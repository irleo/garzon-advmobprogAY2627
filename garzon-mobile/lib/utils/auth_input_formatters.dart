import 'package:flutter/services.dart';

abstract final class AuthInputFormatters {
  // Reject invalid edits, including pasted text, rather than silently changing
  // an email address or phone number into a different value.
  static TextInputFormatter _allow(RegExp pattern) =>
      TextInputFormatter.withFunction((
        TextEditingValue oldValue,
        TextEditingValue newValue,
      ) {
        if (!newValue.composing.isCollapsed) return newValue;
        return pattern.hasMatch(newValue.text) ? newValue : oldValue;
      });

  static final List<TextInputFormatter> name = <TextInputFormatter>[
    _allow(RegExp(r"^[\p{L}\p{M} '\-]*$", unicode: true)),
    LengthLimitingTextInputFormatter(80),
  ];
  static final List<TextInputFormatter> username = <TextInputFormatter>[
    _allow(RegExp(r'^[a-zA-Z0-9_]*$')),
    LengthLimitingTextInputFormatter(30),
  ];
  static final List<TextInputFormatter> age = <TextInputFormatter>[
    _allow(RegExp(r'^[0-9]*$')),
    LengthLimitingTextInputFormatter(3),
  ];
  static final List<TextInputFormatter> contact = <TextInputFormatter>[
    _allow(RegExp(r'^\+?[0-9]{0,15}$')),
  ];
  static final List<TextInputFormatter> email = <TextInputFormatter>[
    _allow(RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~@\-]*$")),
    LengthLimitingTextInputFormatter(254),
  ];
  static final List<TextInputFormatter> password = <TextInputFormatter>[
    LengthLimitingTextInputFormatter(128),
  ];
  static final List<TextInputFormatter> deletion = <TextInputFormatter>[
    _allow(RegExp(r'^[A-Z]*$')),
    LengthLimitingTextInputFormatter(6),
  ];
}
