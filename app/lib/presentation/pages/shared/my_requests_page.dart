import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/presentation/pages/user/request_detail_page.dart';

/// Reusable "My Requests" page for STAFF and ADMIN roles.
/// Shows requests raised by the current user with filtering by status group.
class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => MyRequestsPageState();
}

class MyRequestsPageState extends State<MyRequestsPage> {
  final _networkClient = NetworkClient();
  List<Request> _requests = [];
  bool _isLoading = true;
  String _filter = 'active';

  void refresh() => _loadRequests();

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await _networkClient.get('/users/requests');
      final data = response.data;
      setState(() {
        _requests = (data['items'] as List)
            .map((json) => Request.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Request> get _filteredRequests {
    switch (_filter) {
      case 'active':
        return _requests
            .where((r) =>
                r.status != 'COMPLETED' &&
                r.status != 'REJECTED' &&
                r.status != 'REPLIED')
            .toList();
      case 'needs_response':
        return _requests.where((r) => r.status == 'REPLIED').toList();
      case 'completed':
        return _requests.where((r) => r.status == 'COMPLETED').toList();
      case 'rejected':
        return _requests.where((r) => r.status == 'REJECTED').toList();
      default:
        return _requests;
    }
  }

  int _countForFilter(String filter) {
    switch (filter) {
      case 'active':
        return _requests
            .where((r) =>
                r.status != 'COMPLETED' &&
                r.status != 'REJECTED' &&
                r.status != 'REPLIED')
            .length;
      case 'needs_response':
        return _requests.where((r) => r.status == 'REPLIED').length;
      case 'completed':
        return _requests.where((r) => r.status == 'COMPLETED').length;
      case 'rejected':
        return _requests.where((r) => r.status == 'REJECTED').length;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterRow(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterPill(
              label: 'Active',
              icon: Icons.pending_actions_rounded,
              count: _countForFilter('active'),
              selected: _filter == 'active',
              onTap: () => setState(() => _filter = 'active'),
            ),
            const SizedBox(width: 8),
            _FilterPill(
              label: 'Needs Response',
              icon: Icons.reply_rounded,
              count: _countForFilter('needs_response'),
              color: const Color(0xFFFAB387),
              selected: _filter == 'needs_response',
              onTap: () => setState(() => _filter = 'needs_response'),
            ),
            const SizedBox(width: 8),
            _FilterPill(
              label: 'Completed',
              icon: Icons.check_circle_rounded,
              count: _countForFilter('completed'),
              color: const Color(0xFFA6E3A1),
              selected: _filter == 'completed',
              onTap: () => setState(() => _filter = 'completed'),
            ),
            const SizedBox(width: 8),
            _FilterPill(
              label: 'Rejected',
              icon: Icons.cancel_rounded,
              count: _countForFilter('rejected'),
              color: const Color(0xFFF38BA8),
              selected: _filter == 'rejected',
              onTap: () => setState(() => _filter = 'rejected'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filteredRequests;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_emptyIcon,
                size: 56, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 14),
            Text(
              _emptyMessage,
              style: TextStyle(
                  fontSize: 16, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            if (_filter == 'active') ...[
              const SizedBox(height: 6),
              Text(
                'Use the + button to raise a new request',
                style: TextStyle(
                    fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3)),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final request = filtered[index];
        final statusColor = _statusColor(request.status);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RequestDetailPage(requestId: request.id),
                ),
              ).then((_) => _loadRequests()),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status icon container
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_statusIcon(request.status),
                          color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  request.statusDisplayText,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: statusColor,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatDate(request.updatedAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                          // Action required banner for REPLIED
                          if (request.status == 'REPLIED') ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAB387)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: const Color(0xFFFAB387)
                                        .withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.priority_high_rounded,
                                      size: 13, color: Color(0xFFFAB387)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Action Required',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFFAB387),
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded,
                        color: cs.onSurface.withValues(alpha: 0.25), size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  IconData get _emptyIcon {
    switch (_filter) {
      case 'needs_response':
        return Icons.mark_email_read_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'rejected':
        return Icons.do_not_disturb_rounded;
      default:
        return Icons.inbox_rounded;
    }
  }

  String get _emptyMessage {
    switch (_filter) {
      case 'needs_response':
        return 'No requests need your response';
      case 'completed':
        return 'No completed requests';
      case 'rejected':
        return 'No rejected requests';
      default:
        return 'No active requests';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
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

  IconData _statusIcon(String status) {
    switch (status) {
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ── Filter pill ───────────────────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.icon,
    required this.count,
    this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeColor = color ?? cs.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.18)
              : const Color(0xFF313244),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? activeColor.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  selected ? activeColor : cs.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? activeColor
                    : cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? activeColor.withValues(alpha: 0.25)
                      : cs.onSurface.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? activeColor
                        : cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
