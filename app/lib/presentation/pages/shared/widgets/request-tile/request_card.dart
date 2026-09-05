import 'package:flutter/material.dart';
import 'package:cncc_portal/domain/entities/request_detail_entity.dart';
import 'package:cncc_portal/presentation/pages/shared/widgets/request-tile/request_dialog.dart';

/// Reusable request card used across all role pages.
/// Shows key info and opens [RequestDialog] on tap.
class RequestCard extends StatelessWidget {
  final RequestDetail detail;
  final VoidCallback? onRefresh;

  const RequestCard({
    super.key,
    required this.detail,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final req = detail.request;
    final statusColor = _statusColor(req.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await showDialog(
              context: context,
              builder: (_) => RequestDialog(detail: detail),
            );
            onRefresh?.call();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: icon + status + arrow
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _statusIcon(req.status),
                        color: statusColor,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        req.statusDisplayText,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const Spacer(),

                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurface.withValues(alpha: 0.25),
                      size: 20,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  req.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 10),

                // Info rows
                _InfoRow(
                  label: 'Raised by',
                  value: _raiserDisplay(detail),
                ),
                const SizedBox(height: 3),

                _InfoRow(
                  label: 'Room',
                  value: req.roomNo,
                ),
                const SizedBox(height: 3),

                _InfoRow(
                  label: 'Type',
                  value: '${req.mainType} › ${req.subType}',
                ),
                const SizedBox(height: 3),

                if (req.status == 'ASSIGNED' ||
                    req.status == 'IN_PROGRESS') ...[
                  _InfoRow(
                    label: 'Assigned to',
                    value: _assigneesDisplay(detail),
                  ),
                  const SizedBox(height: 3),
                ],

                _InfoRow(
                  label: 'Updated',
                  value: _fmt(req.updatedAt),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _raiserDisplay(RequestDetail detail) {
    final u = detail.users[detail.request.raisedBy];
    if (u == null) return detail.request.raisedBy;
    final name = (u.name != null && u.name!.trim().isNotEmpty) ? u.name! : null;
    return name != null ? '$name · ${u.email}' : u.email;
  }

  String _assigneesDisplay(RequestDetail detail) {
    final active = detail.assignments.where((a) => a.isActive).toList();
    if (active.isEmpty) return '—';
    return active.map((a) {
      final u = detail.users[a.staffId];
      if (u == null) return a.staffId;
      final name =
          (u.name != null && u.name!.trim().isNotEmpty) ? u.name! : null;
      return name != null ? '$name · ${u.email}' : u.email;
    }).join(', ');
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'RAISED':
        return const Color(0xFF89B4FA);
      case 'REPLIED':
        return const Color(0xFFFAB387);
      case 'ASSIGNED':
        return const Color(0xFFCBA6F7);
      case 'IN_PROGRESS':
        return const Color(0xFFF9E2AF);
      case 'COMPLETED':
        return const Color(0xFFA6E3A1);
      case 'REJECTED':
        return const Color(0xFFF38BA8);
      case 'REASSIGN_REQUESTED':
        return const Color(0xFFEBA0AC);
      default:
        return const Color(0xFF6C7086);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'RAISED':
        return Icons.fiber_new_rounded;
      case 'REPLIED':
        return Icons.reply_rounded;
      case 'ASSIGNED':
        return Icons.assignment_ind_rounded;
      case 'IN_PROGRESS':
        return Icons.pending_rounded;
      case 'COMPLETED':
        return Icons.check_circle_rounded;
      case 'REJECTED':
        return Icons.cancel_rounded;
      case 'REASSIGN_REQUESTED':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _fmt(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
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
          width: 72,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}
