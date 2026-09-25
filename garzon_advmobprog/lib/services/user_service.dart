import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';
import '../models/signup_data.dart';
import 'firebase_account_service.dart';
import 'auth_exception.dart';

export 'auth_exception.dart';

class UserService {
  UserService({http.Client? client, this.firebase})
    : _client = client ?? http.Client();

  static const String sessionKey = 'lab4.userSession';
  final http.Client _client;
  final FirebaseAccountGateway? firebase;

  FirebaseAccountGateway get _firebaseAccount =>
      firebase ??
      (throw const UserServiceException('Firebase is not configured.'));

  Future<User> signIn(
    String identifier,
    String password, {
    required LoginType loginType,
  }) async {
    try {
      if (loginType == LoginType.dummyJson) {
        return await loginUser(identifier, password);
      }
      await _clearSavedSession();
      return await _firebaseAccount.signIn(identifier, password);
    } on Object {
      rethrow;
    }
  }

  Future<User> createAccount(SignUpData data) async {
    try {
      await _clearSavedSession();
      return await _firebaseAccount.createAccount(data);
    } on Object {
      rethrow;
    }
  }

  Future<User?> getUserData() => restoreSession();
  Future<User> updateUsername(String username) =>
      _firebaseAccount.updateUsername(username);
  Future<void> resetPasswordFromCurrentPassword(
    String currentPassword,
    String newPassword,
  ) => _firebaseAccount.changePassword(currentPassword, newPassword);

  Future<void> deleteAccount(String currentPassword) async {
    try {
      await _firebaseAccount.deleteAccount(currentPassword);
      await logout();
    } on Object {
      rethrow;
    }
  }

  Future<void> signOut() => logout();

  // Lab Activity 4 - Enhancement 2: Authenticate and persist the typed user.
  Future<User> loginUser(String username, String password) async {
    try {
      if (firebase?.hasSession ?? false) await _firebaseAccount.signOut();
      final Map<String, dynamic> data = await _request(
        () => _client.post(
          Uri.parse('$apiHost/auth/login'),
          headers: const <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(<String, Object>{
            'username': username.trim(),
            'password': password,
            'expiresInMins': 60,
          }),
        ),
      );
      final User user = User.fromJson(data);
      if (user.accessToken.isEmpty) {
        throw const UserServiceException(
          'The server did not return a session.',
        );
      }
      await saveUserData(user);
      return user;
    } on FormatException {
      throw const UserServiceException('The server returned an invalid user.');
    }
  }

  Future<void> saveUserData(User user) async {
    try {
      if (user.loginType != LoginType.dummyJson) {
        throw StateError('Firebase sessions belong to the Firebase SDK.');
      }
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      // The lab uses preferences for its demo session; never save the password.
      final bool saved = await preferences.setString(
        sessionKey,
        jsonEncode(user.toJson()),
      );
      if (!saved) throw StateError('Session was not saved.');
    } on Object {
      throw const UserServiceException(
        'Unable to save your sign-in on this device.',
      );
    }
  }

  Future<User?> getUser() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final String? saved = preferences.getString(sessionKey);
      if (saved == null) return null;
      final Object? decoded = jsonDecode(saved);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid saved session.');
      }
      final User user = User.fromJson(decoded);
      if (user.accessToken.isEmpty) {
        await logout();
        return null;
      }
      return user;
    } on FormatException {
      await logout();
      return null;
    } on UserServiceException {
      rethrow;
    } on Object {
      throw const UserServiceException('Unable to read your saved sign-in.');
    }
  }

  // Lab Activity 4 - Enhancement 1: Restore and validate persistent authentication.
  Future<User?> restoreSession() async {
    if (firebase?.hasSession ?? false) {
      try {
        await _clearSavedSession();
        return await _firebaseAccount.restoreSession();
      } on Object {
        rethrow;
      }
    }
    final User? saved = await getUser();
    if (saved == null) return null;
    try {
      return await _validateSession(saved);
    } on UserServiceException catch (error) {
      if (!error.isUnauthorized) rethrow;
      if (saved.refreshToken.isEmpty) {
        await logout();
        return null;
      }
      try {
        final Map<String, dynamic> tokens = await _request(
          () => _client.post(
            Uri.parse('$apiHost/auth/refresh'),
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, Object>{
              'refreshToken': saved.refreshToken,
              'expiresInMins': 60,
            }),
          ),
        );
        final User refreshed = User.fromJson(<String, dynamic>{
          ...saved.toJson(),
          ...tokens,
        });
        return await _validateSession(refreshed);
      } on UserServiceException catch (refreshError) {
        if (!refreshError.isUnauthorized && refreshError.statusCode != 400) {
          rethrow;
        }
        await logout();
        return null;
      }
    }
  }

  Future<User> _validateSession(User saved) async {
    try {
      final Map<String, dynamic> profile = await _request(
        () => _client.get(
          Uri.parse('$apiHost/auth/me'),
          headers: <String, String>{
            'Authorization': 'Bearer ${saved.accessToken}',
          },
        ),
      );
      final User user = User.fromJson(<String, dynamic>{
        ...profile,
        'accessToken': saved.accessToken,
        'refreshToken': saved.refreshToken,
      });
      await saveUserData(user);
      return user;
    } on FormatException {
      throw const UserServiceException(
        'The server returned an invalid profile.',
      );
    }
  }

  Future<void> logout() async {
    try {
      if (firebase?.hasSession ?? false) await _firebaseAccount.signOut();
      await _clearSavedSession();
    } on Object {
      throw const UserServiceException('Unable to sign out. Please try again.');
    }
  }

  Future<void> _clearSavedSession() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      if (!await preferences.remove(sessionKey)) {
        throw StateError('Session was not removed.');
      }
    } on Object {
      throw const UserServiceException('Unable to sign out. Please try again.');
    }
  }

  Future<Map<String, dynamic>> _request(
    Future<http.Response> Function() send,
  ) async {
    try {
      final http.Response response = await send().timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw UserServiceException(
          response.statusCode == 400 || response.statusCode == 401
              ? 'Sign-in failed. Check your username and password.'
              : 'The sign-in server is unavailable. Please try again.',
          statusCode: response.statusCode,
        );
      }
      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid response.');
      }
      return decoded;
    } on TimeoutException {
      throw const UserServiceException(
        'The request timed out. Please try again.',
      );
    } on http.ClientException {
      throw const UserServiceException(
        'Unable to connect. Check your internet connection.',
      );
    } on FormatException {
      throw const UserServiceException('The server returned unreadable data.');
    }
  }

  void close() => _client.close();
}
