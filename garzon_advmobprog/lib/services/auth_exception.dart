class UserServiceException implements Exception {
  const UserServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;
  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}
