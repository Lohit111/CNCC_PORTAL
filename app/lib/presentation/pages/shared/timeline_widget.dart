import 'package:flutter/material.dart';
import 'package:cncc_portal/domain/entities/track_entity.dart';
import 'package:cncc_portal/domain/entities/user_entity.dart';

/// Reusable vertical timeline widget.
/// Pass [timeline] (list of Track) and [users] map (uid → User).
class TimelineWidget extends StatelessWidget {
  final List<Track> timeline;
  final Map<String, User> users;

  const TimelineWidget({
    super.key,
    required this.timeline,
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return Center(
        child: Text(
          'No timeline events yet',
          style: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: timeline.length,
      itemBuilder: (context, index) {
        final track = timeline[index];
        final isLast = index == timeline.length - 1;
        final performer = users[track.performedBy];
        final performerName =
            performer?.name ?? performer?.email ?? track.performedBy;

        return _TimelineItem(
          track: track,
          performerName: performerName,
          isLast: isLast,
        );
      },
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Track track;
  final String performerName;
  final bool isLast;

  const _TimelineItem({
    required this.track,
    required this.performerName,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _eventColor(track.eventType);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(_eventIcon(track.eventType), size: 14, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: cs.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          track.eventDisplayText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        _fmt(track.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$performerName · ${track.performedByRole}',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  if (track.comment != null &&
                      track.comment!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        track.comment!.trim(),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _eventColor(String eventType) {
    switch (eventType) {
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
      case 'STORE_REQUEST_CREATED':
      case 'STORE_REQUEST_APPROVED':
      case 'STORE_REQUEST_FULFILLED':
        return const Color(0xFF94E2D5);
      case 'STORE_REQUEST_REJECTED':
        return const Color(0xFFF38BA8);
      default:
        return const Color(0xFF6C7086);
    }
  }

  IconData _eventIcon(String eventType) {
    switch (eventType) {
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
      case 'STORE_REQUEST_CREATED':
        return Icons.store_rounded;
      case 'STORE_REQUEST_APPROVED':
        return Icons.verified_rounded;
      case 'STORE_REQUEST_REJECTED':
        return Icons.store_mall_directory_rounded;
      case 'STORE_REQUEST_FULFILLED':
        return Icons.inventory_rounded;
      default:
        return Icons.circle_outlined;
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
