import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/presentation/pages/user/request_detail_page.dart';

class CompletedRequestsUserPage extends StatefulWidget {
  const CompletedRequestsUserPage({super.key});

  @override
  State<CompletedRequestsUserPage> createState() =>
      _CompletedRequestsUserPageState();
}

class _CompletedRequestsUserPageState extends State<CompletedRequestsUserPage> {
  final _networkClient = NetworkClient();
  List<Request> _requests = [];
  bool _isLoading = true;
  String _filter = 'ALL';

  Map<int, String> _mainTypeNames = {};
  Map<int, String> _subTypeNames = {};

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _networkClient.get('/users/requests'),
        _networkClient.get('/types/main'),
      ]);

      final requestData = results[0].data;
      final mainTypes = results[1].data as List;

      final mainTypeNames = <int, String>{
        for (final t in mainTypes) (t['id'] as int): t['name'] as String,
      };

      final filtered = (requestData['items'] as List)
          .map((json) => Request.fromJson(json))
          .where((req) => req.status == 'COMPLETED' || req.status == 'REJECTED')
          .toList();

      final subTypeNames = <int, String>{};
      final mainTypeIds = filtered.map((r) => r.mainTypeId).toSet().toList();
      await Future.wait(mainTypeIds.map((mid) async {
        try {
          final res = await _networkClient.get('/types/main/$mid/sub');
          for (final s in res.data as List) {
            subTypeNames[s['id'] as int] = s['name'] as String;
          }
        } catch (_) {}
      }));

      setState(() {
        _requests = filtered;
        _mainTypeNames = mainTypeNames;
        _subTypeNames = subTypeNames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Request> get _filteredRequests {
    if (_filter == 'ALL') return _requests;
    return _requests.where((req) => req.status == _filter).toList();
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
              onTap: () => setState(() => _filter = 'ALL')),
          const SizedBox(width: 8),
          _FilterPill(
              label: 'Completed',
              count: _requests.where((r) => r.status == 'COMPLETED').length,
              color: const Color(0xFFA6E3A1),
              selected: _filter == 'COMPLETED',
              onTap: () => setState(() => _filter = 'COMPLETED')),
          const SizedBox(width: 8),
          _FilterPill(
              label: 'Rejected',
              count: _requests.where((r) => r.status == 'REJECTED').length,
              color: const Color(0xFFF38BA8),
              selected: _filter == 'REJECTED',
              onTap: () => setState(() => _filter = 'REJECTED')),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filteredRequests;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt_rounded,
                size: 56,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2)),
            const SizedBox(height: 14),
            Text(
              'No ${_filter == 'ALL' ? 'archived' : _filter.toLowerCase()} requests',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _CompletedCard(
        request: filtered[index],
        mainTypeName: _mainTypeNames[filtered[index].mainTypeId] ?? '—',
        subTypeName: _subTypeNames[filtered[index].subTypeId] ?? '—',
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
        final performedById = lastTrack['performed_by'] as String?;
        _closedByRole = lastTrack['performed_by_role'] as String?;
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
          ),
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
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: color,
                    size: 20,
                  ),
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

                      // Info rows
                      _InfoRow(label: 'Main Type', value: widget.mainTypeName),
                      const SizedBox(height: 2),
                      _InfoRow(label: 'Sub Type', value: widget.subTypeName),
                      const SizedBox(height: 2),
                      _InfoRow(
                          label: 'Created',
                          value: _formatDateTime(request.createdAt)),
                      const SizedBox(height: 2),
                      _InfoRow(
                          label: 'Updated',
                          value: _formatDateTime(request.updatedAt)),

                      // Closed by — async
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
                        if (_closedByRole != null ||
                            _closedByEmail != null) ...[
                          const SizedBox(height: 2),
                          _InfoRow(
                            label: 'Closed by',
                            value: [
                              if (_closedByRole != null) _closedByRole!,
                              if (_closedByEmail != null) _closedByEmail!,
                            ].join(' · '),
                          ),
                        ],
                      ],

                      const SizedBox(height: 8),

                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          request.statusDisplayText,
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w600),
                        ),
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
              : const Color.fromARGB(255, 234, 249, 248),
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
