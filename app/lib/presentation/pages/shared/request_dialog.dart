import 'package:flutter/material.dart';
import 'package:cncc_portal/domain/entities/request_detail_entity.dart';
import 'package:cncc_portal/presentation/pages/shared/timeline_widget.dart';

/// Full-detail dialog for a request.
/// Shows request info, timeline, assignments, and store requests.
class RequestDialog extends StatelessWidget {
  final RequestDetail detail;

  const RequestDialog({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final req = detail.request;

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
              Container(
                margin: const EdgeInsets.only(right: 12),
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
                  ),
                ),

                // Assignments (if any)
                if (detail.assignments.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _Section(
                    title: 'Assignments',
                    child: Column(
                      children: detail.assignments.map((a) {
                        final staff = detail.users[a.staffId];
                        final name = staff?.name ?? staff?.email ?? a.staffId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(
                                a.isActive
                                    ? Icons.person_rounded
                                    : Icons.person_off_rounded,
                                size: 16,
                                color: a.isActive
                                    ? cs.primary
                                    : cs.onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: a.isActive
                                        ? cs.onSurface
                                        : cs.onSurface.withValues(alpha: 0.4),
                                    decoration: a.isActive
                                        ? null
                                        : TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                              if (!a.isActive)
                                Text(
                                  'Inactive',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withValues(alpha: 0.35),
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
