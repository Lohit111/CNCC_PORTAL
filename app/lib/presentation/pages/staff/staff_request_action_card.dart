import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/domain/entities/request_detail_entity.dart';
import 'package:cncc_portal/presentation/providers/staff_provider.dart';
import 'package:cncc_portal/presentation/pages/shared/request_card.dart';
import 'package:cncc_portal/presentation/pages/store/store_chat_page.dart';

/// Staff request card with context-specific action buttons.
class StaffRequestActionCard extends ConsumerWidget {
  final RequestDetail detail;
  final String category;

  const StaffRequestActionCard({
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
          onRefresh: () => ref.read(staffProvider(category).notifier).refresh(),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              // Assigned — can start or request reassignment
              if (category == 'assigned') ...[
                Expanded(
                  child: _ActionBtn(
                    label: 'Start',
                    icon: Icons.play_arrow_rounded,
                    color: const Color(0xFFA6E3A1),
                    onTap: () => _confirmStart(context, ref),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: 'Reassign',
                    icon: Icons.swap_horiz_rounded,
                    color: const Color(0xFFF9E2AF),
                    onTap: () => _showReassignDialog(context, ref),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: 'Store Req',
                    icon: Icons.store_rounded,
                    color: const Color(0xFF94E2D5),
                    onTap: () => _showStoreRequestDialog(context, ref),
                  ),
                ),
              ],
              // In Progress — can finish, request reassignment, or create store request
              if (category == 'inprogress') ...[
                Expanded(
                  child: _ActionBtn(
                    label: 'Finish',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFFA6E3A1),
                    onTap: () => _confirmFinish(context, ref),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: 'Reassign',
                    icon: Icons.swap_horiz_rounded,
                    color: const Color(0xFFF9E2AF),
                    onTap: () => _showReassignDialog(context, ref),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: 'Store Req',
                    icon: Icons.store_rounded,
                    color: const Color(0xFF94E2D5),
                    onTap: () => _showStoreRequestDialog(context, ref),
                  ),
                ),
              ],
              // Archive — view store chats if any
              if (category == 'archive') ...[
                if (detail.storeRequests.isNotEmpty)
                  Expanded(
                    child: _ActionBtn(
                      label: 'View Chat',
                      icon: Icons.chat_rounded,
                      color: const Color(0xFF89B4FA),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoreChatPage(
                            storeRequestId: detail.storeRequests.first.id,
                            description: detail.storeRequests.first.description,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _confirmStart(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Request'),
        content: const Text('Mark this request as in progress?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(staffProvider(category).notifier)
                  .startRequest(detail.request.id);
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _confirmFinish(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Request'),
        content: const Text('Mark this request as completed?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(staffProvider(category).notifier)
                  .finishRequest(detail.request.id);
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _showReassignDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Reassignment'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Why do you need reassignment?',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await ref
                  .read(staffProvider(category).notifier)
                  .requestReassignment(detail.request.id, ctrl.text.trim());
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showStoreRequestDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Store Request'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Describe what you need from the store...',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await ref
                  .read(staffProvider(category).notifier)
                  .createStoreRequest(detail.request.id, ctrl.text.trim());
            },
            child: const Text('Submit'),
          ),
        ],
      ),
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
