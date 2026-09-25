import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

import '../models/signup_data.dart';
import '../models/user.dart';
import 'auth_exception.dart';
import 'profile_repository.dart';

abstract interface class FirebaseAccountGateway {
  bool get hasSession;
  Future<User?> restoreSession();
  Future<User> signIn(String email, String password);
  Future<User> createAccount(SignUpData data);
  Future<User> getUserData();
  Future<User> updateUsername(String username);
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<void> deleteAccount(String currentPassword);
  Future<void> signOut();
}

class FirebaseAccountService implements FirebaseAccountGateway {
  FirebaseAccountService({
    auth.FirebaseAuth? authentication,
    ProfileRepository? profiles,
  }) : _auth = authentication ?? auth.FirebaseAuth.instance,
       _profiles = profiles ?? FirestoreProfileRepository();

  final auth.FirebaseAuth _auth;
  final ProfileRepository _profiles;

  @override
  bool get hasSession => _auth.currentUser != null;

  auth.User get _current =>
      _auth.currentUser ??
      (throw const UserServiceException(
        'Sign in again to manage your account.',
      ));

  @override
  Future<User?> restoreSession() => _perform(() async {
    if (!hasSession) return null;
    try {
      await _current.reload();
      // Firebase manages persistence and refresh; do not copy tokens to preferences.
      await _current.getIdToken(true);
      return await getUserData();
    } on auth.FirebaseAuthException catch (error) {
      if (<String>{
        'user-disabled',
        'user-not-found',
        'user-token-expired',
        'invalid-user-token',
      }.contains(error.code)) {
        await _auth.signOut();
        return null;
      }
      rethrow;
    }
  });

  @override
  Future<User> signIn(String email, String password) => _perform(() async {
    final String? error = AuthValidation.email(email);
    if (error != null) throw UserServiceException(error);
    if (password.isEmpty) {
      throw const UserServiceException('Enter your password.');
    }
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return await getUserData();
  });

  @override
  Future<User> createAccount(SignUpData data) => _perform(() async {
    data.validate(creatingAccount: !hasSession);
    if (hasSession) {
      if (_current.email?.toLowerCase() != data.email.trim().toLowerCase()) {
        throw const UserServiceException(
          'Sign out before creating another account.',
        );
      }
      await _reauthenticate(data.password);
    } else {
      await _auth.createUserWithEmailAndPassword(
        email: data.email.trim(),
        password: data.password,
      );
    }
    try {
      await _profiles.save(_current.uid, data.toProfile());
      return await getUserData();
    } on FirebaseException {
      // Auth and Firestore are not an atomic transaction. Keep the new account
      // so the same form can safely retry, or sign-in can resume profile setup.
      throw const UserServiceException(
        'Your account exists, but the profile could not be saved. Check your '
        'connection and Firestore rules, then retry this form or sign in to finish setup.',
      );
    }
  });

  @override
  Future<User> getUserData() => _perform(() async {
    final auth.User account = _current;
    final Map<String, dynamic>? saved = await _profiles.read(account.uid);
    final Map<String, dynamic> data = saved ?? <String, dynamic>{};
    String text(String key) => data[key] is String ? data[key] as String : '';
    final int? age = data['age'] is int ? data['age'] as int : null;
    final bool complete =
        saved != null &&
        AuthValidation.name(text('firstName')) == null &&
        AuthValidation.name(text('lastName')) == null &&
        AuthValidation.username(text('username')) == null &&
        AuthValidation.contact(text('contactNo')) == null &&
        AuthValidation.age(age?.toString()) == null;
    return User(
      id: null,
      loginType: LoginType.firebase,
      firebaseUid: account.uid,
      username: text('username').isEmpty
          ? (account.displayName ?? '')
          : text('username'),
      email: account.email ?? '',
      firstName: text('firstName'),
      lastName: text('lastName'),
      age: age,
      contactNo: text('contactNo'),
      gender: '',
      image: account.photoURL ?? '',
      accessToken: '',
      refreshToken: '',
      profileComplete: complete,
    );
  });

  @override
  Future<User> updateUsername(String username) => _perform(() async {
    final String? error = AuthValidation.username(username);
    if (error != null) throw UserServiceException(error);
    await _profiles.updateUsername(_current.uid, username.trim());
    return await getUserData();
  });

  Future<void> _reauthenticate(String password) async {
    try {
      final String? email = _current.email;
      if (email == null || password.isEmpty) {
        throw const UserServiceException('Enter your current password.');
      }
      await _current.reauthenticateWithCredential(
        auth.EmailAuthProvider.credential(email: email, password: password),
      );
    } on auth.FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) =>
      _perform(() async {
        final String? error = AuthValidation.password(newPassword);
        if (error != null) throw UserServiceException(error);
        if (currentPassword == newPassword) {
          throw const UserServiceException('Choose a different new password.');
        }
        await _reauthenticate(currentPassword);
        await _current.updatePassword(newPassword);
      });

  @override
  Future<void> deleteAccount(String currentPassword) => _perform(() async {
    await _reauthenticate(currentPassword);
    final auth.User account = _current;
    final Map<String, dynamic>? backup = await _profiles.read(account.uid);
    // Delete the profile while its owner can still authorize the operation.
    await _profiles.delete(account.uid);
    try {
      await account.delete();
    } on Object {
      if (backup != null) {
        try {
          await _profiles.restore(account.uid, backup);
        } on Object {
          throw const UserServiceException(
            'Account deletion could not be confirmed and the profile could not '
            'be restored. Sign in again to check the account and retry deletion.',
          );
        }
      }
      rethrow;
    }
  });

  @override
  Future<void> signOut() => _perform(_auth.signOut);

  Future<T> _perform<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on UserServiceException {
      rethrow;
    } on auth.FirebaseAuthException catch (error) {
      throw UserServiceException(switch (error.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'Email or password is incorrect.',
        'email-already-in-use' =>
          'This email already has an account. Sign in instead.',
        'weak-password' =>
          'Choose a stronger password that meets the password policy.',
        'invalid-email' => 'Enter a valid email address.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' =>
          'Unable to connect. Check your internet connection.',
        'requires-recent-login' ||
        'user-token-expired' ||
        'invalid-user-token' =>
          'Your session expired. Sign out and sign in again.',
        'user-disabled' => 'This account has been disabled.',
        'operation-not-allowed' =>
          'Email/Password sign-in is not enabled in Firebase.',
        _ => 'Authentication failed (${error.code}). Please try again.',
      });
    } on FirebaseException catch (error) {
      throw UserServiceException(
        error.code == 'permission-denied'
            ? 'Profile access was denied. Check the Firestore security rules.'
            : 'Unable to access your profile (${error.code}). Please try again.',
      );
    } on FormatException catch (error) {
      throw UserServiceException(error.message);
    }
  }
}
