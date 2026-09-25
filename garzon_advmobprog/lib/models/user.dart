enum LoginType { dummyJson, firebase }

// Firebase UIDs remain distinct from DummyJSON's numeric IDs.
class User {
  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.image,
    required this.accessToken,
    required this.refreshToken,
    this.loginType = LoginType.dummyJson,
    this.firebaseUid,
    this.age,
    this.contactNo = '',
    this.profileComplete = true,
  });

  final int? id;
  final LoginType loginType;
  final String? firebaseUid;
  final int? age;
  final String contactNo;
  final bool profileComplete;

  String get accountId => firebaseUid ?? id.toString();
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String image;
  final String accessToken;
  final String refreshToken;

  String get fullName => '$firstName $lastName'.trim();

  factory User.fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    if (id is! int || id <= 0) {
      throw const FormatException('The user response has an invalid ID.');
    }
    String field(String key) {
      final Object? value = json[key];
      if (value == null) return '';
      if (value is! String) {
        throw FormatException('The user field $key must be text.');
      }
      return value;
    }

    final String accessToken = field('accessToken');
    return User(
      id: id,
      username: field('username'),
      email: field('email'),
      firstName: field('firstName'),
      lastName: field('lastName'),
      gender: field('gender'),
      image: field('image'),
      accessToken: accessToken.isEmpty ? field('token') : accessToken,
      refreshToken: field('refreshToken'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'username': username,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'gender': gender,
    'image': image,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };
}
