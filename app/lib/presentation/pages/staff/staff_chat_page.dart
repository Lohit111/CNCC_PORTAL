import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/presentation/providers/auth_provider.dart';
import 'package:cncc_portal/presentation/providers/staff_provider.dart';
import 'package:cncc_portal/domain/entities/store_chat_entity.dart';
import 'package:cncc_portal/core/network/network_client.dart';

/// Chat page for staff to communicate about a store request.
/// Uses the staff-specific POST /staff/chat/{id} endpoint.
class StaffChatPage extends ConsumerStatefulWidget {
  final String storeRequestId;
  final String description;

  const StaffChatPage({
    super.key,
    required this.storeRequestId,
    required this.description,
  });

  @override
  ConsumerState<StaffChatPage> createState() => _StaffChatPageState();
}

class _StaffChatPageState extends ConsumerState<StaffChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  List<StoreChat> _messages = [];
  bool _isLoading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _pollMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final res =
          await NetworkClient().get('/staff/chat/${widget.storeRequestId}');
      final msgs = (res.data as List)
          .map((e) => StoreChat.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  /// Silent background refresh — no loading spinner, only scrolls if new
  /// messages arrived so it doesn't interrupt the user while typing.
  Future<void> _pollMessages() async {
    if (!mounted) return;
    try {
      final res =
          await NetworkClient().get('/staff/chat/${widget.storeRequestId}');
      final msgs = (res.data as List)
          .map((e) => StoreChat.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      final hadNew = msgs.length > _messages.length;
      setState(() => _messages = msgs);
      if (hadNew) _scrollToBottom();
    } catch (_) {
      // silent — polling failures are non-fatal
    }
  }

  Future<void> _send() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await ref
          .read(staffProvider('inprogress').notifier)
          .sendChatMessage(widget.storeRequestId, msg);
      _messageController.clear();
      await _loadMessages();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentUserId = ref.watch(authProvider).user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Chat'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              widget.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.4)),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _ChatBubble(
                          message: _messages[i],
                          isMe: _messages[i].senderId == currentUserId,
                        ),
                      ),
          ),
          // Input bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                    top: BorderSide(
                        color: cs.onSurface.withValues(alpha: 0.08))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: cs.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _send,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.send_rounded, color: cs.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final StoreChat message;
  final bool isMe;

  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.primary.withValues(alpha: 0.12),
              child: Icon(Icons.store_rounded, size: 14, color: cs.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? cs.primary.withValues(alpha: 0.12)
                    : cs.surfaceContainerLow,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(fontSize: 14, color: cs.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmt(message.createdAt),
                    style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}
