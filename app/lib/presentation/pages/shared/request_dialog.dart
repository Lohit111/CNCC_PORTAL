import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/domain/entities/request_detail_entity.dart';
import 'package:cncc_portal/presentation/pages/shared/timeline_widget.dart';
import 'package:cncc_portal/presentation/providers/auth_provider.dart';
import 'package:cncc_portal/presentation/providers/admin_provider.dart';

/// Full-detail dialog for a request.
/// Shows request info, timeline, assignments, and store requests.
/// Admins get a delete button in the app bar.
class RequestDialog extends ConsumerWidget {
  final RequestDetail detail;

  const RequestDialog({super.key, required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final req = detail.request;
    final isAdmin = ref.watch(authProvider).user?.role == 'ADMIN';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            title: Text(
              '${req.mainType} · ${req.subType}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Status badge
              Container(
                margin: EdgeInsets.only(right: isAdmin ? 4 : 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(req.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  req.statusDisplayText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(req.status),
                  ),
                ),
              ),
              // Admin delete button
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFF38BA8)),
                  tooltip: 'Delete',
                  onPressed: () =>
                      _showDeleteSheet(context, ref, isAdmin: true),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Request info
                _Section(
                  title: 'Request Details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(
                          label: 'Raised by', value: detail.raiserDisplay),
                      const SizedBox(height: 6),
                      _DetailRow(label: 'Room', value: req.roomNo),
                      const SizedBox(height: 6),
                      _DetailRow(label: 'Phone', value: req.phoneNo),
                      const SizedBox(height: 6),
                      _DetailRow(
                          label: 'Created', value: _fmtFull(req.createdAt)),
                      const SizedBox(height: 10),
                      Text(
                        req.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withValues(alpha: 0.85),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Timeline
                _Section(
                  title: 'Timeline',
                  child: TimelineWidget(
                    timeline: detail.timeline,
                    users: detail.users,
                    assignments: detail.assignments,
                  ),
                ),

                // Active assignments (if any)
                if (detail.assignments.any((a) => a.isActive)) ...[
                  const SizedBox(height: 20),
                  _Section(
                    title: 'Currently Assigned',
                    child: Column(
                      children:
                          detail.assignments.where((a) => a.isActive).map((a) {
                        final staff = detail.users[a.staffId];
                        final name = staff?.name ?? staff?.email ?? a.staffId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(Icons.person_rounded,
                                  size: 16, color: cs.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA6E3A1)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  'Active',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFA6E3A1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // Store requests (if any)
                if (detail.storeRequests.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _Section(
                    title: 'Store Requests',
                    child: Column(
                      children: detail.storeRequests.map((sr) {
                        final requester = detail.users[sr.requestedBy];
                        final requesterName = requester?.name ??
                            requester?.email ??
                            sr.requestedBy;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        sr.description,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _srStatusColor(sr.status)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        sr.statusDisplayText,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: _srStatusColor(sr.status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'By $requesterName',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withValues(alpha: 0.45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delete sheet
  // ---------------------------------------------------------------------------

  void _showDeleteSheet(BuildContext context, WidgetRef ref,
      {required bool isAdmin}) {
    final cs = Theme.of(context).colorScheme;
    final req = detail.request;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Delete entire request
                _DeleteTile(
                  icon: Icons.delete_forever_rounded,
                  label: 'Delete Request',
                  sublabel:
                      '${req.mainType} · ${req.subType} — removes everything',
                  color: const Color(0xFFF38BA8),
                  onTap: () async {
                    Navigator.pop(sheetCtx); // close sheet
                    final confirmed = await _confirmDelete(
                        context,
                        'Delete entire request?',
                        'This will permanently delete the request and all '
                            'its timeline events, assignments, store requests, '
                            'and chat messages.');
                    if (!confirmed) return;
                    final ok = await ref
                        .read(adminProvider(_categoryForStatus(req.status))
                            .notifier)
                        .deleteRequest(req.id);
                    if (context.mounted) {
                      Navigator.pop(context); // close the RequestDialog
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(ok
                            ? 'Request deleted'
                            : 'Failed to delete request'),
                      ));
                    }
                  },
                ),

                // Individual store request deletes
                if (detail.storeRequests.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Divider(color: cs.onSurface.withValues(alpha: 0.08)),
                  const SizedBox(height: 4),
                  Text(
                    'Store Requests',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...detail.storeRequests.map((sr) => _DeleteTile(
                        icon: Icons.store_rounded,
                        label: sr.description,
                        sublabel: sr.statusDisplayText,
                        color: const Color(0xFFF9E2AF),
                        onTap: () async {
                          Navigator.pop(sheetCtx);
                          final confirmed = await _confirmDelete(
                              context,
                              'Delete store request?',
                              '"${sr.description}" and its chat messages will '
                                  'be permanently removed.');
                          if (!confirmed) return;
                          final ok = await ref
                              .read(
                                  adminProvider(_categoryForStatus(req.status))
                                      .notifier)
                              .deleteStoreRequest(sr.id);
                          if (context.mounted) {
                            Navigator.pop(context); // close RequestDialog
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ok
                                  ? 'Store request deleted'
                                  : 'Failed to delete store request'),
                            ));
                          }
                        },
                      )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(
      BuildContext context, String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF38BA8)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Maps a request status to the adminProvider category key so the notifier
  /// can be found and refreshed after deletion.
  String _categoryForStatus(String status) {
    switch (status) {
      case 'RAISED':
        return 'raised';
      case 'REPLIED':
        return 'replied';
      case 'ASSIGNED':
        return 'assigned';
      case 'REASSIGN_REQUESTED':
        return 'reassign-requested';
      case 'IN_PROGRESS':
        return 'inprogress';
      default:
        return 'archive';
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

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

  Color _srStatusColor(String s) {
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

  String _fmtFull(DateTime date) =>
      '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Delete tile widget
// ---------------------------------------------------------------------------

class _DeleteTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _DeleteTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.45)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: cs.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared section / detail widgets
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withValues(alpha: 0.5),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
