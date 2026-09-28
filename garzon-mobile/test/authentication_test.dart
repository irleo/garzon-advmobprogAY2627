import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garzon_advmobprog/models/user.dart';
import 'package:garzon_advmobprog/screens/signin_screen.dart';
import 'package:garzon_advmobprog/screens/splash_screen.dart';
import 'package:garzon_advmobprog/services/user_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Map<String, dynamic> _userData = <String, dynamic>{
  'id': 7,
  'username': 'student',
  'firstName': 'Test',
  'lastName': 'Student',
  'email': 'student@example.com',
  'gender': 'female',
  'image': '',
  'accessToken': 'demo-access',
  'refreshToken': 'demo-refresh',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('login saves a typed user and never saves the password', () async {
    final UserService service = UserService(
      client: MockClient((http.Request request) async {
        expect(request.url.path, '/auth/login');
        expect(jsonDecode(request.body), <String, Object>{
          'username': 'student',
          'password': 'test-password',
          'expiresInMins': 60,
        });
        return http.Response(jsonEncode(_userData), 200);
      }),
    );
    addTearDown(service.close);
    final User user = await service.loginUser(' student ', 'test-password');
    expect(user.id, 7);
    expect((await service.getUser())?.fullName, 'Test Student');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(UserService.sessionKey),
      isNot(contains('test-password')),
    );
  });

  test('invalid credentials do not create a saved session', () async {
    final UserService service = UserService(
      client: MockClient((_) async => http.Response('{}', 400)),
    );
    addTearDown(service.close);
    await expectLater(
      service.loginUser('student', 'wrong'),
      throwsA(isA<UserServiceException>()),
    );
    expect(await service.getUser(), isNull);
  });

  test('a new service restores a saved session through auth/me', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      UserService.sessionKey: jsonEncode(_userData),
    });
    final UserService service = UserService(
      client: MockClient((http.Request request) async {
        expect(request.url.path, '/auth/me');
        expect(request.headers['Authorization'], 'Bearer demo-access');
        return http.Response(jsonEncode(_userData), 200);
      }),
    );
    addTearDown(service.close);
    expect((await service.restoreSession())?.id, 7);
  });

  test('expired access refreshes and persists new tokens', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      UserService.sessionKey: jsonEncode(_userData),
    });
    int requests = 0;
    final UserService service = UserService(
      client: MockClient((http.Request request) async {
        requests++;
        if (requests == 1) return http.Response('{}', 401);
        if (request.url.path == '/auth/refresh') {
          return http.Response(
            jsonEncode(<String, String>{
              'accessToken': 'new-access',
              'refreshToken': 'new-refresh',
            }),
            200,
          );
        }
        expect(request.headers['Authorization'], 'Bearer new-access');
        return http.Response(jsonEncode(_userData), 200);
      }),
    );
    addTearDown(service.close);
    expect((await service.restoreSession())?.accessToken, 'new-access');
    expect((await service.getUser())?.refreshToken, 'new-refresh');
    expect(requests, 3);
  });

  test(
    'rejected session is cleared but unrelated preferences survive',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        UserService.sessionKey: jsonEncode(_userData),
        'theme': 'dark',
      });
      final UserService service = UserService(
        client: MockClient((_) async => http.Response('{}', 401)),
      );
      addTearDown(service.close);
      expect(await service.restoreSession(), isNull);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(UserService.sessionKey), isFalse);
      expect(prefs.getString('theme'), 'dark');
    },
  );

  test('network failure preserves the session for retry', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      UserService.sessionKey: jsonEncode(_userData),
    });
    final UserService service = UserService(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    addTearDown(service.close);
    await expectLater(
      service.restoreSession(),
      throwsA(isA<UserServiceException>()),
    );
    expect((await service.getUser())?.id, 7);
  });

  test('corrupt session recovers to signed out', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      UserService.sessionKey: '{broken',
    });
    final UserService service = UserService();
    addTearDown(service.close);
    expect(await service.getUser(), isNull);
    expect(
      (await SharedPreferences.getInstance()).containsKey(
        UserService.sessionKey,
      ),
      isFalse,
    );
  });

  test('logout removes the saved session', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      UserService.sessionKey: jsonEncode(_userData),
    });
    final UserService service = UserService();
    addTearDown(service.close);
    await service.logout();
    expect(await service.getUser(), isNull);
  });

  test('legacy token key is parsed and invalid user IDs are rejected', () {
    expect(
      User.fromJson(<String, dynamic>{'id': 1, 'token': 'legacy'}).accessToken,
      'legacy',
    );
    expect(
      () => User.fromJson(<String, dynamic>{'id': 0}),
      throwsFormatException,
    );
  });

  testWidgets('empty sign-in fields show validation without an API request', (
    WidgetTester tester,
  ) async {
    int requests = 0;
    final UserService service = UserService(
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 400);
      }),
    );
    addTearDown(service.close);
    await tester.pumpWidget(
      Provider<UserService>.value(
        value: service,
        child: const MaterialApp(home: SignInScreen()),
      ),
    );
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Enter your username.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(requests, 0);
  });

  testWidgets('splash routes a missing session to sign-in', (
    WidgetTester tester,
  ) async {
    final UserService service = UserService();
    addTearDown(service.close);
    await tester.pumpWidget(
      Provider<UserService>.value(
        value: service,
        child: MaterialApp(
          home: const SplashScreen(),
          routes: <String, WidgetBuilder>{
            SignInScreen.routeName: (_) => const SignInScreen(),
          },
        ),
      ),
    );
    await tester.pump(SplashScreen.minimumDisplayDuration);
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
