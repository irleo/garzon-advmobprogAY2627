class SignUpData {
  const SignUpData({
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.contactNo,
    required this.username,
    required this.email,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final int age;
  final String contactNo;
  final String username;
  final String email;
  final String password;

  // Credentials are deliberately excluded from the profile document.
  Map<String, Object> toProfile() => <String, Object>{
    'firstName': firstName.trim(),
    'lastName': lastName.trim(),
    'age': age,
    'contactNo': contactNo.trim(),
    'username': username.trim(),
  };

  void validate({bool creatingAccount = true}) {
    final String? error =
        AuthValidation.name(firstName) ??
        AuthValidation.name(lastName) ??
        AuthValidation.age(age.toString()) ??
        AuthValidation.contact(contactNo) ??
        AuthValidation.username(username) ??
        AuthValidation.email(email) ??
        (creatingAccount
            ? AuthValidation.password(password)
            : password.isEmpty
            ? 'Enter your current password.'
            : null);
    if (error != null) throw FormatException(error);
  }
}

abstract final class AuthValidation {
  static String? name(String? value) =>
      value == null ||
          value.trim().isEmpty ||
          value.trim().length > 80 ||
          !RegExp(
            r"^[\p{L}\p{M}]+(?:[ '\-][\p{L}\p{M}]+)*$",
            unicode: true,
          ).hasMatch(value.trim()) ||
          !RegExp(r'\p{L}', unicode: true).hasMatch(value)
      ? 'Use 1–80 letters, with spaces, apostrophes, or hyphens between names.'
      : null;

  static String? username(String? value) =>
      value == null || !RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(value.trim())
      ? 'Use 3–30 letters, numbers, or underscores.'
      : null;

  static String? email(String? value) {
    final String address = value?.trim() ?? '';
    final List<String> parts = address.split('@');
    if (address.length > 254 || parts.length != 2) {
      return 'Enter a valid email address.';
    }
    final String local = parts.first;
    final List<String> domain = parts.last.split('.');
    if (local.isEmpty ||
        local.length > 64 ||
        local.startsWith('.') ||
        local.endsWith('.') ||
        local.contains('..') ||
        !RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~\-]+$").hasMatch(local) ||
        domain.length < 2 ||
        domain.any(
          (String label) =>
              label.length > 63 ||
              !RegExp(
                r'^[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?$',
              ).hasMatch(label),
        ) ||
        !RegExp(r'^[a-zA-Z]{2,63}$').hasMatch(domain.last)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? age(String? value) {
    final int? number = int.tryParse(value ?? '');
    return !RegExp(r'^[0-9]{1,3}$').hasMatch(value ?? '') ||
            number == null ||
            number < 1 ||
            number > 120
        ? 'Enter an age from 1 to 120.'
        : null;
  }

  static String? contact(String? value) =>
      value == null || !RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value.trim())
      ? 'Enter 7–15 digits, optionally starting with +.'
      : null;

  static String? password(String? value) =>
      value == null ||
          value.length < 8 ||
          value.length > 128 ||
          !RegExp(r'[a-z]').hasMatch(value) ||
          !RegExp(r'[A-Z]').hasMatch(value) ||
          !RegExp(r'[0-9]').hasMatch(value)
      ? 'Use 8–128 characters with uppercase, lowercase, and a number.'
      : null;
}
