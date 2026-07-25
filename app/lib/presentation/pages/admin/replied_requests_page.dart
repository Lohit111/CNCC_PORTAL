import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/domain/entities/type_entity.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_request_detail_page.dart';

class RepliedRequestsPage extends StatefulWidget {
  const RepliedRequestsPage({super.key});

  @override
  State<RepliedRequestsPage> createState() => _RepliedRequestsPageState();
}

class _RepliedRequestsPageState extends State<RepliedRequestsPage> {
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
      final response = await _networkClient.get('/requests/');
      final data = response.data;
      final requests = (data['items'] as List)
          .map((json) => Request.fromJson(json))
          .where((req) => req.status == 'REPLIED' && req.isActive == 'true')
          .toList();
      await _loadTypeNames(requests);
      setState(() {
        _requests = requests;
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
        title: const Text('Replied'),
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

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_read_rounded,
                size: 56, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 14),
            Text('No replied requests',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 4),
            Text('Waiting for user responses',
                style: TextStyle(
                    fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return _RepliedCard(
          request: request,
          mainTypeName: _mainTypeNames[request.mainTypeId] ?? '—',
          subTypeName: _subTypeNames[request.subTypeId] ?? '—',
        );
      },
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _RepliedCard extends StatefulWidget {
  final Request request;
  final String mainTypeName;
  final String subTypeName;

  const _RepliedCard({
    required this.request,
    required this.mainTypeName,
    required this.subTypeName,
  });

  @override
  State<_RepliedCard> createState() => _RepliedCardState();
}

class _RepliedCardState extends State<_RepliedCard> {
  final _networkClient = NetworkClient();
  String? _repliedByEmail;
  String? _repliedByRole;
  String? _replyComment;
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
        _repliedByRole = lastTrack['performed_by_role'] as String?;
        _replyComment = lastTrack['comment'] as String?;
        final performedById = lastTrack['performed_by'] as String?;
        if (performedById != null) {
          try {
            final emailRes =
                await _networkClient.get('/users/emails?ids=$performedById');
            if (emailRes.data is Map) {
              _repliedByEmail =
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
    const accent = Color(0xFFFAB387);

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
                  // Description
                  Text(
                    widget.request.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14, color: cs.onSurface, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  // Info rows
                  _InfoRow(label: 'Main Type', value: widget.mainTypeName),
                  const SizedBox(height: 3),
                  _InfoRow(label: 'Sub Type', value: widget.subTypeName),
                  const SizedBox(height: 3),
                  _InfoRow(
                      label: 'Updated at',
                      value: _formatDate(widget.request.updatedAt)),
                  if (_extraLoading) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: cs.onSurface.withValues(alpha: 0.3)),
                    ),
                  ] else ...[
                    if (_repliedByEmail != null || _repliedByRole != null) ...[
                      const SizedBox(height: 3),
                      _InfoRow(
                        label: 'Replied by',
                        value: [
                          if (_repliedByRole != null) _repliedByRole!,
                          if (_repliedByEmail != null) _repliedByEmail!,
                        ].join(' · '),
                      ),
                    ],
                    if (_replyComment != null &&
                        _replyComment!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: accent.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.reply_rounded,
                                size: 13, color: accent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _replyComment!.trim(),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurface.withValues(alpha: 0.8),
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AdminRequestDetailPage(requestId: widget.request.id),
                    ),
                  ),
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

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year} '
      '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
                fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withValues(alpha: 0.8)),
          ),
        ),
      ],
    );
  }
}
