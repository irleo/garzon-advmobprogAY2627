import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.pending,
    required this.seen,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime? timestamp;
  final bool pending;
  final bool seen;

  factory Message.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data();
    String field(String key) {
      final Object? value = data[key];
      if (value is! String) throw FormatException('Invalid message $key.');
      return value;
    }

    final Object? timestamp = data['timestamp'];
    return Message(
      id: doc.id,
      senderId: field('senderId'),
      receiverId: field('receiverId'),
      text: field('message'),
      timestamp: timestamp is Timestamp ? timestamp.toDate() : null,
      pending: doc.metadata.hasPendingWrites,
      seen: data['seenAt'] is Timestamp,
    );
  }
}
