import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/store_request_entity.dart';

class PendingStoreRequestsPage extends StatefulWidget {
  const PendingStoreRequestsPage({super.key});

  @override
  State<PendingStoreRequestsPage> createState() =>
      _PendingStoreRequestsPageState();
}

class _PendingStoreRequestsPageState extends State<PendingStoreRequestsPage> {
  final _networkClient = NetworkClient();
  List<StoreRequest> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await _networkClient.get('/store-requests/status/PENDING');
      final data = response.data;
      setState(() {
        _requests = (data['items'] as List)
            .map((json) => StoreRequest.fromJson(json))
            .toList();
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
        title: const Text('Pending'),
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
      return _emptyState(
        icon: Icons.inbox_rounded,
        message: 'No pending requests',
        sub: 'New equipment requests will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _requests.length,
      itemBuilder: (context, index) =>
          _PendingCard(request: _requests[index], onRefresh: _loadRequests),
    );
  }

  Widget _emptyState(
      {required IconData icon, required String message, required String sub}) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 14),
          Text(message,
              style: TextStyle(
                  fontSize: 16, color: cs.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 4),
          Text(sub,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3))),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final StoreRequest request;
  final VoidCallback onRefresh;

  const _PendingCard({required this.request, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const accent = Color(0xFFF9E2AF); // yellow for pending

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
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.pending_rounded,
                        color: accent, size: 20),
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
                        Text(
                          _formatDate(request.createdAt),
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.4)),
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
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showRespondDialog(context, request, 'APPROVED'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA6E3A1),
                        foregroundColor: Colors.black87,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label:
                          const Text('Approve', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showRespondDialog(context, request, 'REJECTED'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF38BA8),
                        foregroundColor: Colors.black87,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label:
                          const Text('Reject', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRespondDialog(
      BuildContext context, StoreRequest request, String status) async {
    final commentController = TextEditingController();
    final isApprove = status == 'APPROVED';
    final color = isApprove ? const Color(0xFFA6E3A1) : const Color(0xFFF38BA8);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isApprove ? 'Approve Request' : 'Reject Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: isApprove
                      ? 'Comment (optional)'
                      : 'Rejection Reason (required)',
                  hintText: isApprove
                      ? 'Items available, preparing...'
                      : 'Items out of stock...',
                ),
                maxLines: 3,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (!isApprove && commentController.text.trim().isEmpty)
                  ? null
                  : () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: color, foregroundColor: Colors.black87),
              child: Text(isApprove ? 'Approve' : 'Reject'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final networkClient = NetworkClient();
        await networkClient
            .post('/store-requests/${request.id}/respond', data: {
          'status': status,
          'response_comment': commentController.text.isEmpty
              ? (isApprove ? 'Request approved' : null)
              : commentController.text,
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(isApprove ? 'Request approved' : 'Request rejected')),
          );
          onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
