import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class ProfileRepository {
  Future<Map<String, dynamic>?> read(String uid);
  Future<void> save(String uid, Map<String, Object> profile);
  Future<void> updateUsername(String uid, String username);
  Future<void> delete(String uid);
  Future<void> restore(String uid, Map<String, dynamic> profile);
}

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository({FirebaseFirestore? database})
    : _database = database ?? FirebaseFirestore.instance;
  final FirebaseFirestore _database;

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
  Future<void> delete(String uid) => _document(uid).delete();

  @override
  Future<void> restore(String uid, Map<String, dynamic> profile) =>
      _document(uid).set(<String, dynamic>{
        ...profile,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
