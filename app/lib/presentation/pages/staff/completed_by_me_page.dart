import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/domain/entities/track_entity.dart';
import 'package:cncc_portal/domain/entities/type_entity.dart';
import 'package:cncc_portal/presentation/providers/auth_provider.dart';

class CompletedByMePage extends ConsumerStatefulWidget {
  const CompletedByMePage({super.key});

  @override
  ConsumerState<CompletedByMePage> createState() => _CompletedByMePageState();
}

class _CompletedByMePageState extends ConsumerState<CompletedByMePage> {
  final _networkClient = NetworkClient();
  List<Request> _requests = [];
  final Map<int, String> _mainTypeNames = {};
  final Map<int, String> _subTypeNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;

      final assignmentsResponse = await _networkClient.get(
        '/assignments/staff/${user.id}',
        queryParameters: {'active_only': false},
      );
      final assignments = assignmentsResponse.data as List;

      final requestsResponse = await _networkClient.get('/requests/');
      final allRequests = (requestsResponse.data['items'] as List)
          .map((json) => Request.fromJson(json))
          .toList();

      final assignedRequestIds =
          assignments.map((a) => a['request_id']).toSet();
      final filtered = allRequests
          .where((req) =>
              assignedRequestIds.contains(req.id) && req.status == 'COMPLETED')
          .toList();
      await _loadTypeNames(filtered);
      setState(() {
        _requests = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTypeNames(List<Request> requests) async {
    try {
      final mainRes = await _networkClient.get('/types/main');
      for (final j in (mainRes.data as List)) {
        final mt = MainType.fromJson(j);
        _mainTypeNames[mt.id] = mt.name;
      }
      for (final mainId in requests.map((r) => r.mainTypeId).toSet()) {
        final subRes = await _networkClient.get('/types/main/$mainId/sub');
        for (final j in (subRes.data as List)) {
          final st = SubType.fromJson(j);
          _subTypeNames[st.id] = st.name;
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed'),
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
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded,
                size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No completed requests',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            Text('Requests you complete will appear here',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.35))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return _CompletedCard(
          request: request,
          mainTypeName: _mainTypeNames[request.mainTypeId] ?? '—',
          subTypeName: _subTypeNames[request.subTypeId] ?? '—',
          onViewTimeline: () => _viewTimeline(request),
        );
      },
    );
  }

  Future<void> _viewTimeline(Request request) async {
    try {
      final response =
          await _networkClient.get('/requests/${request.id}/timeline');
      final tracks =
          (response.data as List).map((json) => Track.fromJson(json)).toList();

      final Map<String, String> performerEmails = {};
      final ids = tracks.map((t) => t.performedBy).toSet().toList();
      if (ids.isNotEmpty) {
        try {
          final queryParams = ids.map((id) => 'ids=$id').join('&');
          final res = await _networkClient.get('/users/emails?$queryParams');
          if (res.data is Map) {
            (res.data as Map).forEach((k, v) {
              performerEmails[k.toString()] = v.toString();
            });
          }
        } catch (_) {}
      }

      if (!mounted) return;

      final cs = Theme.of(context).colorScheme;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Request Timeline'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                final email = performerEmails[track.performedBy] ?? 'Unknown';
                final actionColor = _colorForAction(track.actionType);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: actionColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_iconForAction(track.actionType),
                          color: actionColor, size: 18),
                    ),
                    title: Text(
                      track.actionDisplayText,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${track.performedByRole} • $email',
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.6)),
                        ),
                        if (track.comment != null)
                          Text(
                            track.comment!,
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.55)),
                          ),
                        Text(
                          track.createdAt.toString().substring(0, 19),
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.4)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading timeline: $e')),
        );
      }
    }
  }

  IconData _iconForAction(String actionType) {
    switch (actionType) {
      case 'RAISED':
        return Icons.add_circle_rounded;
      case 'REPLIED':
        return Icons.reply_rounded;
      case 'ASSIGNED':
        return Icons.person_add_rounded;
      case 'IN_PROGRESS':
        return Icons.work_rounded;
      case 'COMPLETED':
        return Icons.check_circle_rounded;
      case 'REASSIGN_REQUESTED':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.circle;
    }
  }

  Color _colorForAction(String actionType) {
    switch (actionType) {
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
      case 'REASSIGN_REQUESTED':
        return const Color(0xFFF38BA8);
      default:
        return const Color(0xFF6C7086);
    }
  }
}

class _CompletedCard extends StatefulWidget {
  final Request request;
  final String mainTypeName;
  final String subTypeName;
  final VoidCallback onViewTimeline;

  const _CompletedCard({
    required this.request,
    required this.mainTypeName,
    required this.subTypeName,
    required this.onViewTimeline,
  });

  @override
  State<_CompletedCard> createState() => _CompletedCardState();
}

class _CompletedCardState extends State<_CompletedCard> {
  final _networkClient = NetworkClient();
  String? _closedByEmail;
  String? _closedByRole;
  bool _extraLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExtra();
  }

  Future<void> _loadExtra() async {
    try {
      final trackRes =
          await _networkClient.get('/requests/${widget.request.id}/timeline');
      final tracks = trackRes.data as List;
      if (tracks.isNotEmpty) {
        final lastTrack = tracks.last;
        _closedByRole = lastTrack['performed_by_role'] as String?;
        final performedById = lastTrack['performed_by'] as String?;
        if (performedById != null) {
          try {
            final emailRes =
                await _networkClient.get('/users/emails?ids=$performedById');
            if (emailRes.data is Map) {
              _closedByEmail =
                  (emailRes.data as Map)[performedById]?.toString();
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
    const accent = Color(0xFFA6E3A1);
    final request = widget.request;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.check_circle_rounded,
                            color: accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          request.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Main Type', value: widget.mainTypeName),
                  const SizedBox(height: 3),
                  _InfoRow(label: 'Sub Type', value: widget.subTypeName),
                  const SizedBox(height: 3),
                  _InfoRow(label: 'Updated at', value: _fmt(request.updatedAt)),
                  const SizedBox(height: 3),
                  _InfoRow(label: 'Created at', value: _fmt(request.createdAt)),
                  if (_extraLoading) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: cs.onSurface.withValues(alpha: 0.3)),
                    ),
                  ] else if (_closedByRole != null ||
                      _closedByEmail != null) ...[
                    const SizedBox(height: 3),
                    _InfoRow(
                      label: 'Closed by',
                      value: [
                        if (_closedByRole != null) _closedByRole!,
                        if (_closedByEmail != null) _closedByEmail!,
                      ].join(' · '),
                    ),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onViewTimeline,
                  icon: const Icon(Icons.timeline_rounded, size: 16),
                  label: const Text('View Timeline',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime date) => '${date.day}/${date.month}/${date.year} '
      '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
          width: 82,
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
