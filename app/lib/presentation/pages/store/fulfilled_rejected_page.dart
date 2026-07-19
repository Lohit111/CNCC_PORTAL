import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/store_request_entity.dart';
import 'package:cncc_portal/presentation/pages/shared/store_chat_page.dart';

class FulfilledRejectedPage extends StatefulWidget {
  const FulfilledRejectedPage({super.key});

  @override
  State<FulfilledRejectedPage> createState() => _FulfilledRejectedPageState();
}

class _FulfilledRejectedPageState extends State<FulfilledRejectedPage> {
  final _networkClient = NetworkClient();
  List<StoreRequest> _requests = [];
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
      final fulfilledRes =
          await _networkClient.get('/store-requests/status/FULFILLED');
      final rejectedRes =
          await _networkClient.get('/store-requests/status/REJECTED');

      final fulfilled = (fulfilledRes.data['items'] as List)
          .map((json) => StoreRequest.fromJson(json))
          .toList();
      final rejected = (rejectedRes.data['items'] as List)
          .map((json) => StoreRequest.fromJson(json))
          .toList();

      setState(() {
        _requests = [...fulfilled, ...rejected];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<StoreRequest> get _filtered {
    if (_filter == 'ALL') return _requests;
    return _requests.where((r) => r.status == _filter).toList();
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
            onTap: () => setState(() => _filter = 'ALL'),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'Fulfilled',
            count: _requests.where((r) => r.status == 'FULFILLED').length,
            color: const Color(0xFFA6E3A1),
            selected: _filter == 'FULFILLED',
            onTap: () => setState(() => _filter = 'FULFILLED'),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = _filtered;
    if (list.isEmpty) {
      final cs = Theme.of(context).colorScheme;
      return Center(
        child: Text(
          'No ${_filter == 'ALL' ? 'completed' : _filter.toLowerCase()} requests',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final request = list[index];
        final isFulfilled = request.status == 'FULFILLED';
        final color =
            isFulfilled ? const Color(0xFFA6E3A1) : const Color(0xFFF38BA8);
        final cs = Theme.of(context).colorScheme;

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
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isFulfilled
                              ? Icons.done_all_rounded
                              : Icons.cancel_rounded,
                          color: color,
                          size: 20,
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
                            const SizedBox(height: 3),
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
                if (request.responseComment != null &&
                    request.responseComment!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.comment_rounded,
                              size: 13,
                              color: cs.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              request.responseComment!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withValues(alpha: 0.7)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (isFulfilled) ...[
                  Divider(
                      height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoreChatPage(
                            storeRequestId: request.id,
                            myRole: 'STORE',
                            title: 'Chat History',
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.history_rounded, size: 16),
                      label: const Text('View Chat History',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
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
