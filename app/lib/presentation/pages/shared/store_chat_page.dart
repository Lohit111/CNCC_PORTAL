import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';

/// Full-screen chat page for a store request.
/// Polls every 5 seconds since there is no WebSocket support yet.
/// [myRole] should be 'STORE' or 'STAFF' — used to align bubbles.
class StoreChatPage extends StatefulWidget {
  final String storeRequestId;
  final String myRole;
  final String title;

  const StoreChatPage({
    super.key,
    required this.storeRequestId,
    required this.myRole,
    this.title = 'Chat',
  });

  @override
  State<StoreChatPage> createState() => _StoreChatPageState();
}

class _StoreChatPageState extends State<StoreChatPage> {
  final _networkClient = NetworkClient();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<dynamic> _chats = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadChats(scrollToBottom: true);
    // Poll every 5 seconds
    _pollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _loadChats());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChats({bool scrollToBottom = false}) async {
    try {
      final response = await _networkClient
          .get('/store-requests/${widget.storeRequestId}/chat');
      if (!mounted) return;
      setState(() {
        _chats = response.data as List;
        _isLoading = false;
      });
      if (scrollToBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _networkClient.post(
        '/store-requests/${widget.storeRequestId}/chat',
        data: {'message': text},
      );
      await _loadChats(scrollToBottom: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
        _messageController.text = text; // restore
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Live indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFA6E3A1),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(cs)),
          _buildInputBar(cs),
        ],
      ),
    );
  }

  Widget _buildMessageList(ColorScheme cs) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              'No messages yet',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 4),
            Text(
              'Start the conversation below',
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.25)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        final chat = _chats[index];
        final isMe = chat['sender_role'] == widget.myRole;
        return _ChatBubble(
          message: chat['message'] as String,
          senderRole: chat['sender_role'] as String,
          isMe: isMe,
        );
      },
    );
  }

  Widget _buildInputBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        border: Border(
            top: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color.fromARGB(255, 234, 249, 248),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: cs.primary,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _sendMessage,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final String senderRole;
  final bool isMe;

  const _ChatBubble({
    required this.message,
    required this.senderRole,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const storeColor = Color(0xFFA6E3A1);
    const staffColor = Color(0xFF89B4FA);
    final bubbleColor = isMe
        ? cs.primary.withValues(alpha: 0.25)
        : const Color.fromARGB(255, 234, 249, 248);
    final roleColor = senderRole == 'STORE' ? storeColor : staffColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                senderRole == 'STORE'
                    ? Icons.store_rounded
                    : Icons.engineering_rounded,
                size: 14,
                color: roleColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        senderRole,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: roleColor,
                        ),
                      ),
                    ),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
