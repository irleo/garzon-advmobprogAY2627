class ChatUser {
  const ChatUser({required this.uid, required this.name, required this.email});

  final String uid;
  final String name;
  final String email;

  factory ChatUser.fromMap(String uid, Map<String, dynamic> data) => ChatUser(
    uid: uid,
    name: data['name'] is String ? data['name'] as String : 'Member',
    email: data['email'] is String ? data['email'] as String : '',
  );

  bool matches(String query) =>
      '$name $email'.toLowerCase().contains(query.trim().toLowerCase());
}
