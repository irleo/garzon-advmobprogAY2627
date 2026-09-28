import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class ProfileRepository {
  Future<Map<String, dynamic>?> read(String uid);
  Future<void> save(String uid, Map<String, Object> profile);
  Future<void> updateUsername(String uid, String username);
  Future<void> delete(String uid);
  Future<void> restore(String uid, Map<String, dynamic> profile);
}

abstract interface class ChatProfilePublisher {
  Future<void> publishChatProfile(String uid, String name, String email);
}

class FirestoreProfileRepository
    implements ProfileRepository, ChatProfilePublisher {
  FirestoreProfileRepository({FirebaseFirestore? database})
    : _database = database ?? FirebaseFirestore.instance;
  final FirebaseFirestore _database;

  @override
  Future<void> publishChatProfile(String uid, String name, String email) async {
    try {
      final DocumentReference<Map<String, dynamic>> document = _database
          .collection('chatUsers')
          .doc(uid);
      final Map<String, dynamic>? existing = (await document.get()).data();
      if (existing?['name'] == name && existing?['email'] == email) return;
      await document.set(<String, Object>{'name': name, 'email': email});
    } on FirebaseException {
      rethrow;
    }
  }

  DocumentReference<Map<String, dynamic>> _document(String uid) =>
      _database.collection('users').doc(uid);

  @override
  Future<Map<String, dynamic>?> read(String uid) async {
    try {
      return (await _document(
        uid,
      ).get(const GetOptions(source: Source.server))).data();
    } on FirebaseException {
      rethrow;
    }
  }

  @override
  Future<void> save(String uid, Map<String, Object> profile) async {
    try {
      final Map<String, dynamic>? existing = await read(uid);
      await _document(uid).set(<String, Object>{
        ...profile,
        if (existing == null) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      rethrow;
    }
  }

  @override
  Future<void> updateUsername(String uid, String username) =>
      _document(uid).update(<String, Object>{
        'username': username,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> delete(String uid) async {
    try {
      final WriteBatch batch = _database.batch();
      batch.delete(_document(uid));
      batch.delete(_database.collection('chatUsers').doc(uid));
      await batch.commit();
    } on FirebaseException {
      rethrow;
    }
  }

  @override
  Future<void> restore(String uid, Map<String, dynamic> profile) =>
      _document(uid).set(<String, dynamic>{
        ...profile,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
