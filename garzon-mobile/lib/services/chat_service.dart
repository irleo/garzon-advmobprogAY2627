import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_user.dart';
import '../models/message.dart';
import '../models/chat_summary.dart';

class ChatService {
  ChatService({FirebaseFirestore? database, FirebaseAuth? authentication})
    : _db = database ?? FirebaseFirestore.instance,
      _auth = authentication ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  String get uid =>
      _auth.currentUser?.uid ??
      (throw StateError('Sign in with Firebase to chat.'));

  // Length-safe encoding avoids collisions between pairs of Firebase UIDs.
  String roomId(String otherUid) {
    final List<String> ids = <String>[uid, otherUid]..sort();
    return base64Url.encode(utf8.encode(jsonEncode(ids)));
  }

  CollectionReference<Map<String, dynamic>> _messages(String otherUid) =>
      _db.collection('chatRooms').doc(roomId(otherUid)).collection('messages');

  // Read existing messages, so older conversations need no backfill.
  Stream<Map<String, ChatSummary>> summaries() {
    final String currentUid = uid;
    final Map<String, ChatSummary> summaries = <String, ChatSummary>{};
    final Map<
      String,
      List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
    >
    listeners = {};
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? rooms;
    late final StreamController<Map<String, ChatSummary>> controller;
    void emit() {
      if (!controller.isClosed) {
        controller.add(Map<String, ChatSummary>.unmodifiable(summaries));
      }
    }

    void error(Object error, StackTrace stack) {
      if (!controller.isClosed) controller.addError(error, stack);
    }

    controller = StreamController<Map<String, ChatSummary>>(
      onListen: () {
        rooms = _db
            .collection('chatRooms')
            .where('participantIds', arrayContains: currentUid)
            .snapshots()
            .listen((snapshot) {
              for (final change in snapshot.docChanges) {
                final Object? raw = change.doc.data()?['participantIds'];
                if (raw is! List) continue;
                final List<String> others = raw
                    .whereType<String>()
                    .where((id) => id != currentUid)
                    .toList();
                if (others.length != 1) continue;
                final String other = others.single;
                if (listeners.containsKey(other)) continue;
                final CollectionReference<Map<String, dynamic>> messages =
                    change.doc.reference.collection('messages');
                summaries[other] = const ChatSummary();
                listeners[other] =
                    <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[
                      messages
                          .orderBy('timestamp', descending: true)
                          .limit(1)
                          .snapshots(includeMetadataChanges: true)
                          .listen((latest) {
                            try {
                              summaries[other] = ChatSummary(
                                latest: latest.docs.isEmpty
                                    ? null
                                    : Message.fromDocument(latest.docs.first),
                                unreadCount: summaries[other]?.unreadCount ?? 0,
                              );
                              emit();
                            } on Object catch (exception, stack) {
                              error(exception, stack);
                            }
                          }, onError: error),
                      messages
                          .where('receiverId', isEqualTo: currentUid)
                          .where('seenAt', isNull: true)
                          .limit(100)
                          .snapshots()
                          .listen((unread) {
                            summaries[other] = ChatSummary(
                              latest: summaries[other]?.latest,
                              unreadCount: unread.docs.length,
                            );
                            emit();
                          }, onError: error),
                    ];
              }
              emit();
            }, onError: error);
      },
      onCancel: () async {
        try {
          await rooms?.cancel();
          for (final subscriptions in listeners.values) {
            for (final subscription in subscriptions) {
              await subscription.cancel();
            }
          }
        } on Object {
          rethrow;
        }
      },
    );
    return controller.stream;
  }

  Stream<List<ChatUser>> users() => _db
      .collection('chatUsers')
      .snapshots()
      .map(
        (QuerySnapshot<Map<String, dynamic>> snapshot) =>
            snapshot.docs
                .where((doc) => doc.id != uid)
                .map((doc) => ChatUser.fromMap(doc.id, doc.data()))
                .toList()
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              ),
      );

  Stream<List<Message>> messages(String otherUid, int limit) async* {
    try {
      // Establish membership before listening, including an empty conversation.
      await _db.collection('chatRooms').doc(roomId(otherUid)).set(
        <String, Object>{
          'participantIds': <String>[uid, otherUid]..sort(),
        },
      );
      yield* _messages(otherUid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) => snapshot.docs.map(Message.fromDocument).toList());
    } on Object {
      rethrow;
    }
  }

  Future<void> send(String otherUid, String text) async {
    try {
      final String trimmed = text.trim();
      if (trimmed.isEmpty || trimmed.length > 2000 || otherUid == uid) {
        throw ArgumentError('Enter a message of 1–2000 characters.');
      }
      final DocumentReference<Map<String, dynamic>> room = _db
          .collection('chatRooms')
          .doc(roomId(otherUid));
      final WriteBatch batch = _db.batch();
      batch.set(room, <String, Object>{
        'participantIds': <String>[uid, otherUid]..sort(),
      });
      batch.set(room.collection('messages').doc(), <String, Object?>{
        'senderId': uid,
        'receiverId': otherUid,
        'message': trimmed,
        'timestamp': FieldValue.serverTimestamp(),
        'seenAt': null,
      });
      await batch.commit();
    } on Object {
      rethrow;
    }
  }

  Future<void> markSeen(String otherUid, DateTime cutoff) async {
    try {
      // Capture a cutoff so messages arriving after this read are handled by
      // the next visible snapshot rather than silently marked as read.
      bool more = true;
      while (more) {
        final QuerySnapshot<Map<String, dynamic>> snapshot =
            await _messages(otherUid)
                .where('receiverId', isEqualTo: uid)
                .where('seenAt', isNull: true)
                .limit(100)
                .get(const GetOptions(source: Source.server));
        final List<QueryDocumentSnapshot<Map<String, dynamic>>> unread =
            snapshot.docs.where((doc) {
              final Object? sent = doc.data()['timestamp'];
              return sent is Timestamp && !sent.toDate().isAfter(cutoff);
            }).toList();
        if (unread.isEmpty) return;
        final WriteBatch batch = _db.batch();
        for (final document in unread) {
          batch.update(document.reference, <String, Object>{
            'seenAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
        more = snapshot.docs.length == 100;
      }
    } on Object {
      rethrow;
    }
  }
}
