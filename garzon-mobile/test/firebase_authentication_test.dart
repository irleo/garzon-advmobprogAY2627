import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garzon_advmobprog/models/product.dart';
import 'package:garzon_advmobprog/models/signup_data.dart';
import 'package:garzon_advmobprog/models/user.dart';
import 'package:garzon_advmobprog/providers/cart_provider.dart';
import 'package:garzon_advmobprog/screens/account_action_screen.dart';
import 'package:garzon_advmobprog/services/cart_service.dart';
import 'package:garzon_advmobprog/services/firebase_account_service.dart';
import 'package:garzon_advmobprog/services/user_service.dart';
import 'package:garzon_advmobprog/services/profile_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const SignUpData _signup = SignUpData(
  firstName: 'Test',
  lastName: 'Student',
  age: 21,
  contactNo: '+639123456789',
  username: 'student',
  email: 'student@example.com',
  password: 'StrongPass1',
);

class _AuthUser extends Fake implements auth.User {
  final List<String> events = <String>[];
  String? reauthError;
  bool deleteFails = false;

  @override
  String get uid => 'firebase-uid';
  @override
  String? get email => 'student@example.com';
  @override
  String? get displayName => null;
  @override
  String? get photoURL => null;
  @override
  Future<void> reload() async => events.add('reload');
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'sdk-token';
  @override
  Future<auth.UserCredential> reauthenticateWithCredential(
    auth.AuthCredential credential,
  ) async {
    events.add('reauthenticate');
    if (reauthError != null) {
      throw auth.FirebaseAuthException(code: reauthError!);
    }
    return _Credential(this);
  }

  @override
  Future<void> updatePassword(String newPassword) async =>
      events.add('password');
  @override
  Future<void> delete() async {
    events.add('delete');
    if (deleteFails) {
      throw auth.FirebaseAuthException(code: 'network-request-failed');
    }
  }
}

class _Credential extends Fake implements auth.UserCredential {
  _Credential(this.user);
  @override
  final auth.User? user;
}

class _Auth extends Fake implements auth.FirebaseAuth {
  _Auth(this.account);
  final _AuthUser account;
  bool active = true;
  int creations = 0;
  @override
  auth.User? get currentUser => active ? account : null;
  @override
  Future<auth.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    active = true;
    return _Credential(account);
  }

  @override
  Future<auth.UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    creations++;
    active = true;
    return _Credential(account);
  }

  @override
  Future<void> signOut() async {
    active = false;
  }
}

class _Document implements ProfileRepository {
  Map<String, dynamic>? value = <String, dynamic>{..._signup.toProfile()};
  bool denyWrites = false;
  int deletes = 0;
  @override
  Future<Map<String, dynamic>?> read(String uid) async {
    expect(uid, 'firebase-uid');
    return value;
  }

  @override
  Future<void> save(String uid, Map<String, Object> data) async {
    if (denyWrites) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    }
    value = <String, dynamic>{...?value, ...data};
  }

  @override
  Future<void> updateUsername(String uid, String username) async {
    value = <String, dynamic>{...?value, 'username': username};
  }

  @override
  Future<void> delete(String uid) async {
    deletes++;
    value = null;
  }

  @override
  Future<void> restore(String uid, Map<String, dynamic> profile) async {
    value = profile;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _AuthUser account;
  late _Auth authentication;
  late _Document document;
  late FirebaseAccountService backend;
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    account = _AuthUser();
    authentication = _Auth(account);
    document = _Document();
    backend = FirebaseAccountService(
      authentication: authentication,
      profiles: document,
    );
  });

  test('profile serialization never includes credentials', () {
    _signup.validate();
    expect(
      _signup.toProfile().keys,
      unorderedEquals(<String>[
        'firstName',
        'lastName',
        'age',
        'contactNo',
        'username',
      ]),
    );
    expect(AuthValidation.password('weak'), isNotNull);
    expect(AuthValidation.contact('abc123'), isNotNull);
    expect(AuthValidation.age('121'), isNotNull);
    expect(AuthValidation.username('bad name'), isNotNull);
  });

  test(
    'Firebase profiles retain UID and never impersonate a DummyJSON user',
    () async {
      final User user = await backend.getUserData();
      expect(user.id, isNull);
      expect(user.firebaseUid, 'firebase-uid');
      expect(user.loginType, LoginType.firebase);
      expect(user.profileComplete, isTrue);
      expect(user.accessToken, isEmpty);
      expect(user.refreshToken, isEmpty);
    },
  );

  test('missing profile allows authenticated profile completion', () async {
    document.value = null;
    expect((await backend.getUserData()).profileComplete, isFalse);
    expect((await backend.createAccount(_signup)).profileComplete, isTrue);
    expect(authentication.creations, 0);
    expect(account.events, contains('reauthenticate'));
  });

  test('successful signup ends the temporary Firebase session', () async {
    authentication.active = false;
    final UserService service = UserService(firebase: backend);
    addTearDown(service.close);
    final User user = await service.createAccount(_signup);
    expect(user.email, _signup.email);
    expect(document.value?['username'], _signup.username);
    expect(authentication.active, isFalse);
    expect(await service.restoreSession(), isNull);
  });

  test(
    'completing an existing profile preserves the signed-in session',
    () async {
      final UserService service = UserService(firebase: backend);
      addTearDown(service.close);
      await service.createAccount(_signup, completingProfile: true);
      expect(authentication.active, isTrue);
    },
  );

  test(
    'profile save retry does not create a second Firebase identity',
    () async {
      authentication.active = false;
      document.value = null;
      document.denyWrites = true;
      await expectLater(
        backend.createAccount(_signup),
        throwsA(isA<UserServiceException>()),
      );
      expect(authentication.creations, 1);
      document.denyWrites = false;
      expect((await backend.createAccount(_signup)).username, 'student');
      expect(authentication.creations, 1);
    },
  );

  test('password changes require reauthentication first', () async {
    await backend.changePassword('OldPassword1', 'NewPassword2');
    expect(account.events, <String>['reauthenticate', 'password']);
  });

  test(
    'wrong current password prevents password change and deletion',
    () async {
      account.reauthError = 'invalid-credential';
      await expectLater(
        backend.changePassword('wrong', 'NewPassword2'),
        throwsA(isA<UserServiceException>()),
      );
      await expectLater(
        backend.deleteAccount('wrong'),
        throwsA(isA<UserServiceException>()),
      );
      expect(account.events, isNot(contains('password')));
      expect(account.events, isNot(contains('delete')));
      expect(document.deletes, 0);
    },
  );

  test('failed identity deletion restores the profile', () async {
    account.deleteFails = true;
    await expectLater(
      backend.deleteAccount('StrongPass1'),
      throwsA(isA<UserServiceException>()),
    );
    expect(document.deletes, 1);
    expect(document.value?['username'], 'student');
  });

  test('username updates persist and return fresh profile data', () async {
    final User updated = await backend.updateUsername('new_name');
    expect(updated.username, 'new_name');
    expect(document.value?['username'], 'new_name');
  });

  test(
    'Firebase restoration clears old DummyJSON session without saving SDK tokens',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        UserService.sessionKey: jsonEncode(<String, Object>{
          'id': 7,
          'accessToken': 'demo',
        }),
        'theme': 'dark',
      });
      final UserService service = UserService(firebase: backend);
      addTearDown(service.close);
      expect((await service.restoreSession())?.firebaseUid, 'firebase-uid');
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      expect(preferences.containsKey(UserService.sessionKey), isFalse);
      expect(preferences.getString('theme'), 'dark');
      await service.logout();
      expect(authentication.active, isFalse);
      expect(await service.restoreSession(), isNull);
    },
  );

  test(
    'Firebase cart never sends UID or numeric aliases to DummyJSON',
    () async {
      int requests = 0;
      final CartProvider provider = CartProvider(
        userId: null,
        cartService: CartService(
          client: MockClient((_) async {
            requests++;
            return http.Response('{}', 500);
          }),
        ),
      );
      addTearDown(provider.dispose);
      await provider.loadCart();
      await provider.addProduct(
        Product.fromJson(<String, dynamic>{
          'id': 1,
          'title': 'Item',
          'price': 10,
          'discountPercentage': 0,
        }),
      );
      await provider.loadCart();
      expect(provider.cart?.totalQuantity, 1);
      await provider.removeProduct(provider.cart!.products.single);
      expect(provider.cart?.totalQuantity, 0);
      expect(requests, 0);
    },
  );

  testWidgets(
    'delete form requires password and explicit DELETE confirmation',
    (WidgetTester tester) async {
      final UserService service = UserService(firebase: backend);
      addTearDown(service.close);
      await tester.pumpWidget(
        Provider<UserService>.value(
          value: service,
          child: const MaterialApp(
            home: AccountActionScreen(
              action: AccountAction.delete,
              username: 'student',
            ),
          ),
        ),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
      await tester.pump();
      expect(find.text('Enter your current password.'), findsOneWidget);
      expect(find.text('Confirmation does not match.'), findsOneWidget);
      expect(document.deletes, 0);
    },
  );
}
