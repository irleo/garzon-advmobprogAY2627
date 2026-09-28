import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat_summary.dart';
import '../models/message.dart';

import '../models/chat_user.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import 'chat_detailscreen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({required this.user, super.key});
  final User user;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _search = TextEditingController();
  ChatService? _service;
  Stream<List<ChatUser>>? _users;
  Stream<Map<String, ChatSummary>>? _summaries;

  @override
  void initState() {
    super.initState();
    if (widget.user.loginType == LoginType.firebase) {
      _service = ChatService();
      _users = _service!.users();
      _summaries = _service!.summaries();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _timeLabel(DateTime? timestamp) {
    if (timestamp == null) return '';
    final DateTime local = timestamp.toLocal();
    final DateTime now = DateTime.now();
    if (DateUtils.isSameDay(local, now)) {
      return DateFormat('h:mm a').format(local);
    }
    if (DateUtils.isSameDay(local, DateTime(now.year, now.month, now.day - 1))) {
      return 'Yesterday';
    }
    return DateFormat(
      local.year == now.year ? 'MMM d' : 'MMM d, y',
    ).format(local);
  }

  @override
  Widget build(BuildContext context) {
    if (_service == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Sign in with a Firebase account to chat with other members.',
          ),
        ),
      );
    }
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SearchBar(
            controller: _search,
            hintText: 'Search by name or email',
            leading: const Icon(Icons.search_rounded),
            trailing: <Widget>[
              if (_search.text.isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(_search.clear),
                ),
            ],
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ChatUser>>(
            stream: _users,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'Unable to load members. Check your connection and rules.',
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _users = _service!.users()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final List<ChatUser> users = snapshot.data!
                  .where((user) => user.matches(_search.text))
                  .toList();
              if (users.isEmpty) {
                return Center(
                  child: Text(
                    _search.text.isEmpty
                        ? 'No other members yet.'
                        : 'No members match your search.',
                  ),
                );
              }
              return StreamBuilder<Map<String, ChatSummary>>(
                stream: _summaries,
                builder: (context, inbox) {
                  final Map<String, ChatSummary> summaries =
                      inbox.data ?? const <String, ChatSummary>{};
                  users.sort((a, b) {
                    final DateTime? first = summaries[a.uid]?.latest?.timestamp;
                    final DateTime? second =
                        summaries[b.uid]?.latest?.timestamp;
                    if (first == null && second == null) {
                      return a.name.compareTo(b.name);
                    }
                    if (first == null) return 1;
                    if (second == null) return -1;
                    return second.compareTo(first);
                  });
                  return Column(
                    children: <Widget>[
                      if (inbox.hasError)
                        MaterialBanner(
                          content: const Text(
                            'Message previews could not load. Check your connection and Firestore rules.',
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => setState(
                                () => _summaries = _service!.summaries(),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: users.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final ChatUser user = users[index];
                            final ChatSummary summary =
                                summaries[user.uid] ?? const ChatSummary();
                            final Message? latest = summary.latest;
                            final bool unread = summary.unreadCount > 0;
                            final ColorScheme colors = Theme.of(
                              context,
                            ).colorScheme;
                            final String preview = latest == null
                                ? (inbox.connectionState ==
                                          ConnectionState.waiting
                                      ? 'Loading conversation…'
                                      : user.email)
                                : '${latest.senderId == _service!.uid ? 'You: ' : ''}${latest.text.replaceAll(RegExp(r'\s+'), ' ')}';
                            return Card(
                              key: ValueKey<String>(user.uid),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                leading: Badge(
                                  isLabelVisible: unread,
                                  backgroundColor: colors.primary,
                                  child: CircleAvatar(
                                    child: Text(
                                      user.name.isEmpty
                                          ? '?'
                                          : user.name.characters.first
                                                .toUpperCase(),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: unread
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    preview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: unread
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: unread
                                          ? colors.onSurface
                                          : colors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    if (latest != null)
                                      Text(
                                        latest.pending
                                            ? 'Sending…'
                                            : _timeLabel(latest.timestamp),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: unread
                                              ? colors.primary
                                              : colors.onSurfaceVariant,
                                          fontWeight: unread
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    if (unread)
                                      Semantics(
                                        label:
                                            '${summary.unreadCount >= 100 ? 'More than 99' : summary.unreadCount} unread messages',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.primary,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            summary.unreadCount >= 100
                                                ? '99+'
                                                : '${summary.unreadCount}',
                                            style: TextStyle(
                                              color: colors.onPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      )
                                    else if (latest?.senderId == _service!.uid)
                                      Icon(
                                        latest!.seen
                                            ? Icons.done_all
                                            : Icons.check,
                                        size: 16,
                                        color: colors.onSurfaceVariant,
                                      )
                                    else
                                      const SizedBox(height: 16),
                                  ],
                                ),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ChatDetailScreen(
                                      user: user,
                                      service: _service!,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
