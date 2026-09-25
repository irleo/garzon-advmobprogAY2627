import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garzon_advmobprog/models/signup_data.dart';
import 'package:garzon_advmobprog/utils/auth_input_formatters.dart';

String edit(List<TextInputFormatter> formatters, String before, String after) {
  final TextEditingValue original = TextEditingValue(text: before);
  return formatters
      .fold<TextEditingValue>(
        TextEditingValue(text: after),
        (TextEditingValue value, TextInputFormatter formatter) =>
            formatter.formatEditUpdate(original, value),
      )
      .text;
}

void main() {
  test(
    'names support legitimate punctuation and Unicode, but reject digits and symbols',
    () {
      for (final String name in <String>[
        "O'Connor",
        'Anne-Marie',
        'José Niño',
        '李 明',
      ]) {
        expect(AuthValidation.name(name), isNull, reason: name);
        expect(edit(AuthInputFormatters.name, '', name), name);
      }
      for (final String name in <String>[
        'User123',
        '<script>',
        'Jane@',
        '---',
        '  ',
        'Jane  Doe',
      ]) {
        expect(AuthValidation.name(name), isNotNull, reason: name);
      }
      expect(edit(AuthInputFormatters.name, 'Jane', 'Jane@123'), 'Jane');
    },
  );

  test('username rejects punctuation, spaces, emoji and overlength values', () {
    expect(AuthValidation.username('user_123'), isNull);
    for (final String value in <String>[
      'ab',
      'a b',
      'a.b',
      'abc!',
      'user😀',
      'a' * 31,
    ]) {
      expect(AuthValidation.username(value), isNotNull);
    }
    expect(edit(AuthInputFormatters.username, 'user', 'user!'), 'user');
    expect(edit(AuthInputFormatters.username, '', 'a' * 31).length, 30);
  });

  test('age accepts whole-number ages only', () {
    for (final String value in <String>[
      '0',
      '121',
      '-1',
      '2.5',
      '+21',
      ' 21',
      'abc',
    ]) {
      expect(AuthValidation.age(value), isNotNull, reason: value);
    }
    expect(AuthValidation.age('21'), isNull);
    expect(edit(AuthInputFormatters.age, '2', '2.5'), '2');
  });

  test('phone rejects letters, embedded plus signs, and invalid lengths', () {
    expect(AuthValidation.contact('+639123456789'), isNull);
    for (final String value in <String>[
      '123',
      '123+4567',
      'abc1234567',
      '1234567890123456',
    ]) {
      expect(AuthValidation.contact(value), isNotNull, reason: value);
    }
    expect(edit(AuthInputFormatters.contact, '+63', '+63+'), '+63');
    expect(edit(AuthInputFormatters.contact, '', 'abc1234567'), '');
  });

  test(
    'email permits useful email punctuation but validates local and domain parts',
    () {
      for (final String value in <String>[
        'student+lab@example.edu.ph',
        "o'connor@example.com",
        'a_b@example.com',
      ]) {
        expect(AuthValidation.email(value), isNull, reason: value);
        expect(edit(AuthInputFormatters.email, '', value), value);
      }
      for (final String value in <String>[
        'a..b@example.com',
        '.a@example.com',
        'a@-example.com',
        'a@example..com',
        'a@exam!ple.com',
        'a b@example.com',
        'a@@example.com',
      ]) {
        expect(AuthValidation.email(value), isNotNull, reason: value);
      }
      expect(edit(AuthInputFormatters.email, 'a', 'a b@example.com'), 'a');
    },
  );

  test(
    'password keeps special characters and enforces strength and length',
    () {
      expect(AuthValidation.password('Strong#Pass1!'), isNull);
      expect(
        edit(AuthInputFormatters.password, '', 'Strong#Pass1!'),
        'Strong#Pass1!',
      );
      expect(AuthValidation.password('weak'), isNotNull);
      expect(AuthValidation.password('alllowercase1'), isNotNull);
      expect(AuthValidation.password('ALLUPPERCASE1'), isNotNull);
      expect(AuthValidation.password('NoNumbers!'), isNotNull);
      expect(AuthValidation.password('${'a' * 128}A1'), isNotNull);
    },
  );
}
