import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/domain/entities/store_request_detail_entity.dart';
import 'package:cncc_portal/presentation/providers/store_provider.dart';
import 'package:cncc_portal/presentation/pages/store/store_chat_page.dart';
import 'package:cncc_portal/presentation/pages/shared/widgets/request-tile/request_dialog.dart';
import 'package:cncc_portal/domain/entities/request_detail_entity.dart';

/// Store request card with context actions (approve/reject/fulfil/chat).
class StoreRequestCard extends ConsumerWidget {
  final StoreRequestDetail detail;
  final String category;

  const StoreRequestCard({
    super.key,
    required this.detail,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final sr = detail.storeRequest;
    final parent = detail.parentRequest;
    final statusColor = _statusColor(sr.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          // Store request card
          Material(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: parent != null
                  ? () => showDialog(
                        context: context,
                        builder: (_) => RequestDialog(
                          detail: RequestDetail(
                            request: parent.request,
                            timeline: parent.timeline,
                            assignments: parent.assignments,
                            storeRequests: const [],
                            users: parent.users,
                          ),
                        ),
                      )
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            sr.statusDisplayText,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor),
                          ),
                        ),
                        const Spacer(),
                        Text(_fmt(sr.createdAt),
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.4))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      sr.description,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (parent != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Request',
                        value:
                            '${parent.request.mainType} · ${parent.request.subType}',
                      ),
                      const SizedBox(height: 3),
                      _InfoRow(
                        label: 'Room',
                        value: parent.request.roomNo,
                      ),
                      const SizedBox(height: 3),
                      _InfoRow(
                        label: 'Requested by',
                        value: () {
                          final u = parent.users[sr.requestedBy];
                          return u?.name ?? u?.email ?? sr.requestedBy;
                        }(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Action buttons
          const SizedBox(height: 4),
          Row(
            children: [
              if (category == 'pending') ...[
                Expanded(
                  child: _ActionBtn(
                    label: 'Approve',
                    icon: Icons.verified_rounded,
                    color: const Color(0xFF94E2D5),
                    onTap: () => _approve(context, ref),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: 'Reject',
                    icon: Icons.cancel_rounded,
                    color: const Color(0xFFF38BA8),
                    onTap: () => _reject(context, ref),
                  ),
                ),
              ],
              if (category == 'approved') ...[
                Expanded(
                  child: _ActionBtn(
                    label: 'Fulfil',
                    icon: Icons.inventory_rounded,
                    color: const Color(0xFFA6E3A1),
                    onTap: () => _fulfil(context, ref),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: 'Chat',
                    icon: Icons.chat_rounded,
                    color: const Color(0xFF89B4FA),
                    onTap: () => _openChat(context),
                  ),
                ),
              ],
              if (category == 'archive') ...[
                Expanded(
                  child: _ActionBtn(
                    label: 'View Parent',
                    icon: Icons.visibility_rounded,
                    color: const Color(0xFF89B4FA),
                    onTap: parent != null
                        ? () => showDialog(
                              context: context,
                              builder: (_) => RequestDialog(
                                detail: RequestDetail(
                                  request: parent.request,
                                  timeline: parent.timeline,
                                  assignments: parent.assignments,
                                  storeRequests: const [],
                                  users: parent.users,
                                ),
                              ),
                            )
                        : null,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  void _approve(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Request'),
        content: const Text('Approve this store request?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(storeProvider(category).notifier)
                  .approve(detail.storeRequest.id);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _reject(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              labelText: 'Reason', hintText: 'Enter rejection reason...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF38BA8)),
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await ref.read(storeProvider(category).notifier).reject(
                    detail.storeRequest.id,
                    ctrl.text.trim(),
                  );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _fulfil(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Fulfilled'),
        content: const Text('Mark this store request as fulfilled?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(storeProvider(category).notifier)
                  .fulfil(detail.storeRequest.id);
            },
            child: const Text('Fulfil'),
          ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreChatPage(
          storeRequestId: detail.storeRequest.id,
          description: detail.storeRequest.description,
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PENDING':
        return const Color(0xFFF9E2AF);
      case 'APPROVED':
        return const Color(0xFF94E2D5);
      case 'REJECTED':
        return const Color(0xFFF38BA8);
      case 'FULFILLED':
        return const Color(0xFFA6E3A1);
      default:
        return const Color(0xFF6C7086);
    }
  }

  String _fmt(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text('$label:',
              style: TextStyle(
                  fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45))),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withValues(alpha: 0.8))),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
