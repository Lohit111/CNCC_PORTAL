import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/domain/entities/type_entity.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_request_detail_page.dart';

class CompletedRequestsPage extends StatefulWidget {
  const CompletedRequestsPage({super.key});

  @override
  State<CompletedRequestsPage> createState() => _CompletedRequestsPageState();
}

class _CompletedRequestsPageState extends State<CompletedRequestsPage> {
  final _networkClient = NetworkClient();
  List<Request> _requests = [];
  final Map<int, String> _mainTypeNames = {};
  final Map<int, String> _subTypeNames = {};
  bool _isLoading = true;
  String _filter = 'ALL';

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
          .where((req) => req.status == 'COMPLETED' || req.status == 'REJECTED')
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

  List<Request> get _filtered {
    if (_filter == 'ALL') return _requests;
    return _requests.where((r) => r.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive'),
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
      child: Row(
        children: [
          _FilterPill(
            label: 'All',
            count: _requests.length,
            selected: _filter == 'ALL',
            onTap: () => setState(() => _filter = 'ALL'),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'Completed',
            count: _requests.where((r) => r.status == 'COMPLETED').length,
            color: const Color(0xFFA6E3A1),
            selected: _filter == 'COMPLETED',
            onTap: () => setState(() => _filter = 'COMPLETED'),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'Rejected',
            count: _requests.where((r) => r.status == 'REJECTED').length,
            color: const Color(0xFFF38BA8),
            selected: _filter == 'REJECTED',
            onTap: () => setState(() => _filter = 'REJECTED'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Text(
          'No ${_filter == 'ALL' ? 'archived' : _filter.toLowerCase()} requests',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: list.length,
      itemBuilder: (context, index) => _CompletedCard(
        request: list[index],
        mainTypeName: _mainTypeNames[list[index].mainTypeId] ?? '—',
        subTypeName: _subTypeNames[list[index].subTypeId] ?? '—',
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _CompletedCard extends StatefulWidget {
  final Request request;
  final String mainTypeName;
  final String subTypeName;

  const _CompletedCard({
    required this.request,
    required this.mainTypeName,
    required this.subTypeName,
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
    final request = widget.request;
    final isCompleted = request.status == 'COMPLETED';
    final color =
        isCompleted ? const Color(0xFFA6E3A1) : const Color(0xFFF38BA8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon + description
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: color,
                          size: 18,
                        ),
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
                  // Info rows
                  _InfoRow(label: 'Main Type', value: widget.mainTypeName),
                  const SizedBox(height: 3),
                  _InfoRow(label: 'Sub Type', value: widget.subTypeName),
                  const SizedBox(height: 3),
                  _InfoRow(
                      label: 'Updated at',
                      value: _formatDate(request.updatedAt)),
                  if (_extraLoading) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: cs.onSurface.withValues(alpha: 0.3)),
                    ),
                  ] else if (_closedByEmail != null ||
                      _closedByRole != null) ...[
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
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AdminRequestDetailPage(requestId: request.id),
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

class _FilterPill extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.18)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                selected ? activeColor.withValues(alpha: 0.5) : Colors.blueGrey,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
