import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat_user.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    required this.user,
    required this.service,
    super.key,
  });
  final ChatUser user;
  final ChatService service;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with WidgetsBindingObserver {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late Stream<List<Message>> _messages;
  int _limit = 50;
  bool _sending = false;
  bool _markingSeen = false;
  String? _receiptSnapshot;
  bool _active = true;
  String? _receiptError;
  List<Message> _latest = <Message>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messages = widget.service.messages(widget.user.uid, _limit);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) _seen();
  }

  Future<void> _seen() async {
    if (!mounted ||
        !_active ||
        _markingSeen ||
        _receiptError != null ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final List<DateTime> timestamps =
        _latest
            .where((message) => !message.pending && message.timestamp != null)
            .map((message) => message.timestamp!)
            .toList()
          ..sort();
    if (timestamps.isEmpty) return;
    final String receiptSnapshot = _latest
        .map((message) => '${message.id}:${message.seen}:${message.pending}')
        .join('|');
    if (_receiptSnapshot == receiptSnapshot) return;
    _receiptSnapshot = receiptSnapshot;
    _markingSeen = true;
    try {
      await widget.service.markSeen(widget.user.uid, timestamps.last);
    } on Object {
      _receiptSnapshot = null;
      if (mounted) {
        setState(() => _receiptError = 'Read receipts could not be saved.');
      }
    } finally {
      _markingSeen = false;
      // A new message can arrive while the previous receipt batch is saving.
      if (mounted && _receiptError == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _seen());
        WidgetsBinding.instance.ensureVisualUpdate();
      }
    }
  }

  Future<void> _send() async {
    final String text = _composer.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.service.send(widget.user.uid, text);
      if (!mounted) return;
      _composer.clear();
      if (_scroll.hasClients) {
        await _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Message could not be sent. Your draft is kept; try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(widget.user.name),
          Text(widget.user.email, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
    body: Column(
      children: <Widget>[
        if (_receiptError != null)
          MaterialBanner(
            content: Text(_receiptError!),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  setState(() {
                    _receiptError = null;
                    _receiptSnapshot = null;
                  });
                  _seen();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        Expanded(
          child: StreamBuilder<List<Message>>(
            stream: _messages,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('Unable to load messages.'),
                      TextButton(
                        onPressed: () => setState(
                          () => _messages = widget.service.messages(
                            widget.user.uid,
                            _limit,
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              _latest = snapshot.data!;
              WidgetsBinding.instance.addPostFrameCallback((_) => _seen());
              if (_latest.isEmpty) {
                return const Center(
                  child: Text('Say hello to start the conversation.'),
                );
              }
              return ListView.builder(
                controller: _scroll,
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: _latest.length + 1,
                itemBuilder: (context, index) {
                  if (index == _latest.length) {
                    return _latest.length < _limit
                        ? const SizedBox.shrink()
                        : TextButton(
                            onPressed: () => setState(() {
                              _limit += 50;
                              _messages = widget.service.messages(
                                widget.user.uid,
                                _limit,
                              );
                            }),
                            child: const Text('Load older messages'),
                          );
                  }
                  final Message message = _latest[index];
                  return _MessageBubble(
                    key: ValueKey<String>(message.id),
                    message: message,
                    mine: message.senderId == widget.service.uid,
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _composer,
                    enabled: !_sending,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Type a message…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: IconButton.filled(
                    tooltip: _sending ? 'Sending…' : 'Send message',
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine, super.key});
  final Message message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String status = message.pending
        ? 'Sending…'
        : message.seen
        ? 'Seen'
        : 'Sent';
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 250),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * .78,
          ),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: mine
                ? colors.primaryContainer
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20).copyWith(
              bottomRight: Radius.circular(mine ? 4 : 20),
              bottomLeft: Radius.circular(mine ? 20 : 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              SelectableText(
                message.text,
                style: TextStyle(
                  color: mine ? colors.onPrimaryContainer : colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  if (message.timestamp != null)
                    Text(
                      DateFormat(
                        'MMM d, h:mm a',
                      ).format(message.timestamp!.toLocal()),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  if (mine) ...<Widget>[
                    Icon(
                      message.pending
                          ? Icons.schedule
                          : message.seen
                          ? Icons.done_all
                          : Icons.check,
                      size: 14,
                      semanticLabel: status,
                    ),
                    Text(status, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
