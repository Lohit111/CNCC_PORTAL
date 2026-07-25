import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/presentation/pages/user/request_detail_page.dart';

class ActiveRequestsPage extends StatefulWidget {
  const ActiveRequestsPage({super.key});

  @override
  State<ActiveRequestsPage> createState() => ActiveRequestsPageState();
}

class ActiveRequestsPageState extends State<ActiveRequestsPage> {
  final _networkClient = NetworkClient();
  List<Request> _requests = [];
  bool _isLoading = true;

  // Shared type name caches loaded once for the page
  Map<int, String> _mainTypeNames = {};
  Map<int, String> _subTypeNames = {};

  void refresh() => _loadRequests();

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      // Load requests and type maps in parallel
      final results = await Future.wait([
        _networkClient.get('/users/requests'),
        _networkClient.get('/types/main'),
      ]);

      final requestData = results[0].data;
      final mainTypes = results[1].data as List;

      // Build main type name map
      final mainTypeNames = <int, String>{
        for (final t in mainTypes) (t['id'] as int): t['name'] as String,
      };

      // Collect all unique sub_type_ids from the active requests to batch-fetch names
      final activeRequests = (requestData['items'] as List)
          .map((json) => Request.fromJson(json))
          .where((req) =>
              req.isActive == 'true' &&
              req.status != 'COMPLETED' &&
              req.status != 'REJECTED' &&
              req.status != 'REPLIED')
          .toList();

      // Fetch sub-type names for each unique main_type_id present
      final subTypeNames = <int, String>{};
      final mainTypeIds =
          activeRequests.map((r) => r.mainTypeId).toSet().toList();
      await Future.wait(mainTypeIds.map((mid) async {
        try {
          final res = await _networkClient.get('/types/main/$mid/sub');
          for (final s in res.data as List) {
            subTypeNames[s['id'] as int] = s['name'] as String;
          }
        } catch (_) {}
      }));

      setState(() {
        _requests = activeRequests;
        _mainTypeNames = mainTypeNames;
        _subTypeNames = subTypeNames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'No active requests',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap + to raise a new request',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _requests.length,
      itemBuilder: (context, index) => _RequestCard(
        request: _requests[index],
        mainTypeName: _mainTypeNames[_requests[index].mainTypeId] ?? '—',
        subTypeName: _subTypeNames[_requests[index].subTypeId] ?? '—',
        onRefresh: _loadRequests,
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _RequestCard extends StatefulWidget {
  final Request request;
  final String mainTypeName;
  final String subTypeName;
  final VoidCallback onRefresh;

  const _RequestCard({
    required this.request,
    required this.mainTypeName,
    required this.subTypeName,
    required this.onRefresh,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  final _networkClient = NetworkClient();

  // Extra data loaded per-card based on status
  String? _performedByEmail; // for ASSIGNED, REASSIGN_REQUESTED
  List<String> _assignedToEmails = []; // for ASSIGNED only
  bool _extraLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExtraData();
  }

  Future<void> _loadExtraData() async {
    final status = widget.request.status;
    if (status == 'RAISED') {
      setState(() => _extraLoading = false);
      return;
    }

    try {
      // For ASSIGNED, REASSIGN_REQUESTED — get last track performer
      if (['ASSIGNED', 'REASSIGN_REQUESTED'].contains(status)) {
        final trackRes =
            await _networkClient.get('/requests/${widget.request.id}/timeline');
        final tracks = trackRes.data as List;
        if (tracks.isNotEmpty) {
          final lastTrack = tracks.last;
          final performedById = lastTrack['performed_by'] as String?;
          if (performedById != null) {
            try {
              final emailRes =
                  await _networkClient.get('/users/emails?ids=$performedById');
              if (emailRes.data is Map) {
                _performedByEmail =
                    (emailRes.data as Map)[performedById]?.toString();
              }
            } catch (_) {}
          }
        }
      }

      // For ASSIGNED and IN_PROGRESS — also get active assigned staff emails
      if (status == 'ASSIGNED' || status == 'IN_PROGRESS') {
        final assignRes = await _networkClient
            .get('/assignments/request/${widget.request.id}');
        final activeAssignments = (assignRes.data as List)
            .where((a) => a['is_active'] == true)
            .toList();

        final ids = activeAssignments
            .map((a) => a['staff_id'] as String)
            .toSet()
            .toList();

        if (ids.isNotEmpty) {
          try {
            final queryParams = ids.map((id) => 'ids=$id').join('&');
            final res = await _networkClient.get('/users/emails?$queryParams');
            if (res.data is Map) {
              _assignedToEmails =
                  (res.data as Map).values.map((v) => v.toString()).toList();
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _extraLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final request = widget.request;
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
          ).then((_) => widget.onRefresh()),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status icon
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
                      // Description
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
                      const SizedBox(height: 8),

                      // Type info — shown for all statuses
                      _InfoRow(label: 'Main Type', value: widget.mainTypeName),
                      const SizedBox(height: 2),
                      _InfoRow(label: 'Sub Type', value: widget.subTypeName),
                      const SizedBox(height: 2),
                      _InfoRow(
                          label: 'Updated',
                          value: _formatDateTime(request.updatedAt)),

                      // Created at — shown for all except RAISED
                      if (request.status != 'RAISED') ...[
                        const SizedBox(height: 2),
                        _InfoRow(
                            label: 'Created',
                            value: _formatDateTime(request.createdAt)),
                      ],

                      // Status-specific extra info
                      if (!_extraLoading) ...[
                        if (request.status == 'ASSIGNED' ||
                            request.status == 'IN_PROGRESS') ...[
                          if (request.status == 'ASSIGNED' &&
                              _performedByEmail != null) ...[
                            const SizedBox(height: 2),
                            _InfoRow(
                                label: 'Assigned by',
                                value: _performedByEmail!),
                          ],
                          if (_assignedToEmails.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            _InfoRow(
                              label: 'Assigned to',
                              value: _assignedToEmails.join(', '),
                            ),
                          ],
                        ],
                        if (request.status == 'REASSIGN_REQUESTED' &&
                            _performedByEmail != null) ...[
                          const SizedBox(height: 2),
                          _InfoRow(
                              label: 'Requested by', value: _performedByEmail!),
                        ],
                      ] else if (request.status != 'RAISED') ...[
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: cs.onSurface.withValues(alpha: 0.3)),
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Status badge
                      Row(
                        children: [
                          _StatusBadge(
                              label: request.statusDisplayText,
                              color: statusColor),
                        ],
                      ),
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
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'RAISED':
        return Icons.fiber_new_rounded;
      case 'ASSIGNED':
        return Icons.assignment_ind_rounded;
      case 'IN_PROGRESS':
        return Icons.pending_rounded;
      case 'REASSIGN_REQUESTED':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'RAISED':
        return const Color(0xFF89B4FA);
      case 'ASSIGNED':
        return const Color(0xFFCBA6F7);
      case 'IN_PROGRESS':
        return const Color(0xFFF9E2AF);
      case 'REASSIGN_REQUESTED':
        return const Color(0xFFF38BA8);
      default:
        return const Color(0xFF6C7086);
    }
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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
          width: 82,
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
              color: cs.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
