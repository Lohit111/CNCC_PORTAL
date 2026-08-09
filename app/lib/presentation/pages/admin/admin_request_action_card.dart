import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/domain/entities/request_detail_entity.dart';
import 'package:cncc_portal/presentation/providers/admin_provider.dart';
import 'package:cncc_portal/presentation/providers/users_provider.dart';
import 'package:cncc_portal/presentation/pages/shared/request_card.dart';
import 'package:cncc_portal/presentation/pages/shared/request_dialog.dart';

/// Admin request card with context-specific action buttons.
/// [category] determines which actions are shown.
class AdminRequestActionCard extends ConsumerWidget {
  final RequestDetail detail;
  final String category;

  const AdminRequestActionCard({
    super.key,
    required this.detail,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        RequestCard(
          detail: detail,
          onRefresh: () => ref.read(adminProvider(category).notifier).refresh(),
        ),
        // Action buttons based on category
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              if (category == 'raised' || category == 'replied') ...[
                Expanded(
                  child: _ActionButton(
                    label: 'Reply',
                    icon: Icons.reply_rounded,
                    color: const Color(0xFFFAB387),
                    onTap: () => _showReplyDialog(context, ref),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: 'Assign',
                    icon: Icons.assignment_ind_rounded,
                    color: const Color(0xFFCBA6F7),
                    onTap: () => _showAssignDialog(context, ref),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: 'Reject',
                    icon: Icons.cancel_rounded,
                    color: const Color(0xFFF38BA8),
                    onTap: () => _showRejectDialog(context, ref),
                  ),
                ),
              ],
              if (category == 'reassign-requested') ...[
                Expanded(
                  child: _ActionButton(
                    label: 'Re-Assign',
                    icon: Icons.assignment_ind_rounded,
                    color: const Color(0xFFCBA6F7),
                    onTap: () => _showAssignDialog(context, ref),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: 'Reject',
                    icon: Icons.cancel_rounded,
                    color: const Color(0xFFF38BA8),
                    onTap: () => _showRejectDialog(context, ref),
                  ),
                ),
              ],
              if (category == 'assigned' || category == 'inprogress') ...[
                Expanded(
                  child: _ActionButton(
                    label: 'View',
                    icon: Icons.visibility_rounded,
                    color: const Color(0xFF89B4FA),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => RequestDialog(detail: detail),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: 'Delete',
                    icon: Icons.delete_rounded,
                    color: const Color(0xFFF38BA8),
                    onTap: () => _confirmDelete(context, ref),
                  ),
                ),
              ],
              if (category == 'archive') ...[
                Expanded(
                  child: _ActionButton(
                    label: 'Delete',
                    icon: Icons.delete_rounded,
                    color: const Color(0xFFF38BA8),
                    onTap: () => _confirmDelete(context, ref),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Reply ────────────────────────────────────────────────────────────────

  void _showReplyDialog(BuildContext context, WidgetRef ref) {
    final commentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reply to Request'),
        content: TextField(
          controller: commentCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Comment',
            hintText: 'Enter your reply...',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (commentCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await ref.read(adminProvider(category).notifier).reply(
                    detail.request.id,
                    commentCtrl.text.trim(),
                  );
            },
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );
  }

  // ── Assign ───────────────────────────────────────────────────────────────

  void _showAssignDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _AssignDialog(
        detail: detail,
        category: category,
      ),
    );
  }

  // ── Reject ───────────────────────────────────────────────────────────────

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final commentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: commentCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Enter rejection reason...',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF38BA8)),
            onPressed: () async {
              if (commentCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await ref.read(adminProvider(category).notifier).reject(
                    detail.request.id,
                    commentCtrl.text.trim(),
                  );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  // ── Delete ───────────────────────────────────────────────────────────────

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Request'),
        content: const Text(
            'This will permanently delete the request and all related data. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF38BA8)),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(adminProvider(category).notifier)
                  .deleteRequest(detail.request.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Assign Dialog ─────────────────────────────────────────────────────────────

class _AssignDialog extends ConsumerStatefulWidget {
  final RequestDetail detail;
  final String category;

  const _AssignDialog({required this.detail, required this.category});

  @override
  ConsumerState<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends ConsumerState<_AssignDialog> {
  final Set<String> _selectedIds = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(usersProvider);
    final staffList =
        usersState.users.where((u) => u.role == 'STAFF' && u.isActive).toList();

    return AlertDialog(
      title: const Text('Assign Staff'),
      content: SizedBox(
        width: double.maxFinite,
        child: usersState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : staffList.isEmpty
                ? const Text('No active staff members found')
                : ListView(
                    shrinkWrap: true,
                    children: staffList.map((u) {
                      final name = u.name ?? u.email;
                      final selected = _selectedIds.contains(u.id);
                      return CheckboxListTile(
                        value: selected,
                        title: Text(name),
                        subtitle:
                            Text(u.email, style: const TextStyle(fontSize: 12)),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIds.add(u.id);
                            } else {
                              _selectedIds.remove(u.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _selectedIds.isEmpty || _isSubmitting
              ? null
              : () async {
                  setState(() => _isSubmitting = true);
                  await ref
                      .read(adminProvider(widget.category).notifier)
                      .assign(
                        widget.detail.request.id,
                        _selectedIds.toList(),
                      );
                  if (mounted) Navigator.pop(context);
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text('Assign (${_selectedIds.length})'),
        ),
      ],
    );
  }
}

// ── Small action button ───────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
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
