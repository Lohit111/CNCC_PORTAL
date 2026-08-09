import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/presentation/providers/my_requests_provider.dart';
import 'package:cncc_portal/presentation/pages/shared/request_card.dart';
import 'package:cncc_portal/domain/entities/request_detail_entity.dart';

class UserRepliedPage extends ConsumerWidget {
  const UserRepliedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myRequestsProvider('replied'));

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        if (data.requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mark_email_read_rounded,
                    size: 56,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.2)),
                const SizedBox(height: 14),
                Text('No requests need your response',
                    style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5))),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.read(myRequestsProvider('replied').notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: data.requests.length,
            itemBuilder: (ctx, i) => _RepliedCard(
              detail: data.requests[i],
              onRefresh: () =>
                  ref.read(myRequestsProvider('replied').notifier).refresh(),
            ),
          ),
        );
      },
    );
  }
}

/// Extended card for REPLIED requests that includes an inline reply action.
class _RepliedCard extends ConsumerStatefulWidget {
  final RequestDetail detail;
  final VoidCallback onRefresh;

  const _RepliedCard({required this.detail, required this.onRefresh});

  @override
  ConsumerState<_RepliedCard> createState() => _RepliedCardState();
}

class _RepliedCardState extends ConsumerState<_RepliedCard> {
  bool _showReply = false;
  final _commentController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _descController.text = widget.detail.request.description;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_commentController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    final success =
        await ref.read(myRequestsProvider('replied').notifier).replyToRequest(
              requestId: widget.detail.request.id,
              comment: _commentController.text.trim(),
              description: _descController.text.trim(),
            );
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        _showReply = false;
        widget.onRefresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        RequestCard(
          detail: widget.detail,
          onRefresh: widget.onRefresh,
        ),
        // Inline reply form
        if (_showReply)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAB387).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFFAB387).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Update Description',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 6),
                TextField(
                  controller: _descController,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(hintText: 'Updated description...'),
                ),
                const SizedBox(height: 10),
                Text('Your Reply',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 6),
                TextField(
                  controller: _commentController,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(hintText: 'Write your reply...'),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _showReply = false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Submit Reply'),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showReply = true),
                icon: const Icon(Icons.reply_rounded, size: 16),
                label: const Text('Reply to Admin'),
              ),
            ),
          ),
      ],
    );
  }
}
