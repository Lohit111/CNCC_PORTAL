import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_request_detail_page.dart';

class CompletedRequestsPage extends StatefulWidget {
  const CompletedRequestsPage({super.key});

  @override
  State<CompletedRequestsPage> createState() => _CompletedRequestsPageState();
}

class _CompletedRequestsPageState extends State<CompletedRequestsPage> {
  final _networkClient = NetworkClient();
  List<Request> _requests = [];
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
      setState(() {
        _requests = (data['items'] as List)
            .map((json) => Request.fromJson(json))
            .where(
                (req) => req.status == 'COMPLETED' || req.status == 'REJECTED')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
      itemBuilder: (context, index) {
        final request = list[index];
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
                  child: Row(
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
                                  color: cs.onSurface),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    request.statusDisplayText,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: color),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(request.updatedAt),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          cs.onSurface.withValues(alpha: 0.4)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
      },
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
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
