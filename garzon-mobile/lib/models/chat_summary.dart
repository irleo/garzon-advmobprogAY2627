import 'message.dart';

class ChatSummary {
  const ChatSummary({this.latest, this.unreadCount = 0});
  final Message? latest;
  // The query stops at 100; the UI displays 99+ at that boundary.
  final int unreadCount;
}
