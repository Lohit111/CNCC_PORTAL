import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cncc_portal/domain/entities/request_detail_entity.dart';
import 'package:cncc_portal/presentation/widgets/request-tile/timeline_widget.dart';
import 'package:cncc_portal/presentation/providers/auth_provider.dart';
import 'package:cncc_portal/presentation/providers/admin_provider.dart';
import 'package:cncc_portal/presentation/widgets/request-tile/helper.dart';

/// Full-detail dialog for a request.
/// Shows request info, timeline, assignments, and store requests.
/// Admins get reject + delete buttons in the app bar.
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
          backgroundColor: const Color(0xFFF4F4F6),
          appBar: AppBar(
            title: Text(
              'Request ID: ${req.id.substring(0, 8).toUpperCase()}',
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
                  color: statusColor(req.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  req.statusDisplayText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor(req.status),
                  ),
                ),
              ),
              // Admin action buttons — reject + delete
              if (isAdmin) ...[
                IconButton(
                  icon: const Icon(Icons.cancel_outlined,
                      color: Color.fromARGB(255, 189, 172, 133)),
                  tooltip: 'Reject',
                  onPressed: () => _showRejectDialog(context, ref),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFF38BA8)),
                  tooltip: 'Delete',
                  onPressed: () =>
                      _showDeleteSheet(context, ref, isAdmin: true),
                ),
              ],
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Request info
                Section(
                  title: 'Request Details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ID row with copy button
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: req.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Request ID copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: cs.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Request ID',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      req.id.substring(0, 8).toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.copy_rounded,
                                size: 20,
                                color: cs.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Edit request button (admin only)
                      if (isAdmin)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => showEditDialog(context, ref, detail),
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: const Text('Edit Request'),
                          ),
                        ),
                      if (isAdmin) const SizedBox(height: 12),
                      DetailRow(
                        label: 'Raised by',
                        value: raiserDisplay(detail),
                      ),
                      const SizedBox(height: 6),
                      DetailRow(label: 'Room', value: req.roomNo),
                      const SizedBox(height: 6),
                      if (req.department.isNotEmpty) ...[
                        DetailRow(label: 'Department', value: req.department),
                        const SizedBox(height: 6),
                      ],
                      DetailRow(
                        label: 'Type',
                        value: '${req.mainType} › ${req.subType}',
                      ),
                      const SizedBox(height: 6),
                      DetailRow(
                          label: 'Created', value: fmtFull(req.createdAt)),
                      const SizedBox(height: 10),
                      Text(
                        req.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withValues(alpha: 0.85),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      CallCreatorRow(detail: detail),
                      const SizedBox(height: 14),
                      DownloadRequestFormButton(requestId: req.id),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Section(
                  title: 'Attachments',
                  child: AttachmentsSection(
                    requestId: req.id,
                    raisedBy: req.raisedBy,
                  ),
                ),

                const SizedBox(height: 20),

                // Timeline
                Section(
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
                  Section(
                    title: 'Currently Assigned',
                    child: Column(
                      children:
                          detail.assignments.where((a) => a.isActive).map((a) {
                        final staff = detail.users[a.staffId];
                        final phone = staff?.phone;
                        final name = staff?.name ?? staff?.email ?? a.staffId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_rounded,
                                size: 16,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 8),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (staff?.email != null)
                                      Text(
                                        staff!.email,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: cs.onSurface
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              if (phone != null)
                                IconButton(
                                  icon: Icon(
                                    Icons.phone_forwarded_rounded,
                                    size: 18,
                                    color: cs.primary,
                                  ),
                                  tooltip: 'Call $name',
                                  onPressed: () async {
                                    final uri = Uri(
                                      scheme: 'tel',
                                      path: phone,
                                    );
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  },
                                ),

                              // Your existing Active badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
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
                // Store requests (if any)
                if (detail.storeRequests.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Section(
                    title: 'Store Requests',
                    child: Column(
                      children: detail.storeRequests.map((sr) {
                        // Requested By
                        final requester = detail.users[sr.requestedBy];
                        final requesterPhone = requester?.phone;
                        final requesterName = requester?.name ??
                            requester?.email ??
                            sr.requestedBy;
                        final requesterEmail =
                            requester?.email ?? sr.requestedBy;

                        // Responded By
                        final responderId = sr.respondedBy;
                        final responder = responderId != null
                            ? detail.users[responderId]
                            : null;
                        final responderPhone = responder?.phone;
                        final responderName =
                            responder?.name ?? responder?.email ?? responderId;
                        final responderEmail =
                            responder?.email ?? sr.respondedBy;

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
                                // Store description
                                Text(
                                  sr.description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Status
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: srStatusColor(sr.status)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    sr.statusDisplayText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: srStatusColor(sr.status),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),
                                // Requested By
                                Text(
                                  'Requested By:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 2),

                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$requesterName · $requesterEmail',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (requesterPhone != null)
                                      IconButton(
                                        icon: Icon(
                                          Icons.phone_forwarded_rounded,
                                          size: 18,
                                          color: cs.primary,
                                        ),
                                        tooltip: 'Call $requesterName',
                                        onPressed: () async {
                                          final uri = Uri(
                                            scheme: 'tel',
                                            path: requesterPhone,
                                          );
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri);
                                          }
                                        },
                                      ),
                                  ],
                                ),

                                // Responded By
                                if (responderId != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Responded By:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          cs.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$responderName · $responderEmail',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (responderPhone != null)
                                        IconButton(
                                          icon: Icon(
                                            Icons.phone_forwarded_rounded,
                                            size: 18,
                                            color: cs.primary,
                                          ),
                                          tooltip:
                                              'Call ${responderName ?? responderId}',
                                          onPressed: () async {
                                            final uri = Uri(
                                              scheme: 'tel',
                                              path: responderPhone,
                                            );
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(uri);
                                            }
                                          },
                                        ),
                                    ],
                                  ),
                                ],
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

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    final req = detail.request;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Enter a reason for rejection...',
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9E2AF)),
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx); // close reason dialog
              final ok = await ref
                  .read(adminProvider(categoryForStatus(req.status)).notifier)
                  .reject(req.id, ctrl.text.trim());
              if (context.mounted) {
                Navigator.pop(context); // close RequestDialog
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      ok ? 'Request rejected' : 'Failed to reject request'),
                ));
              }
            },
            child:
                const Text('Reject', style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

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
                DeleteTile(
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
                    final message = await ref
                        .read(adminProvider(categoryForStatus(req.status))
                            .notifier)
                        .deleteRequest(req.id);

                    if (context.mounted) {
                      Navigator.pop(context); // close the RequestDialog

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message ?? 'Delete failed.'),
                        ),
                      );
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
                  ...detail.storeRequests.map((sr) => DeleteTile(
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
                          final message = await ref
                              .read(
                                  adminProvider(categoryForStatus(req.status))
                                      .notifier)
                              .deleteStoreRequest(sr.id);

                          if (context.mounted) {
                            Navigator.pop(
                                context); // close the StoreRequestDialog

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message ?? 'Delete failed.'),
                              ),
                            );
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
}
