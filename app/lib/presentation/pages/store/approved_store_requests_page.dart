import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/store_request_entity.dart';
import 'package:cncc_portal/presentation/pages/shared/store_chat_page.dart';

class ApprovedStoreRequestsPage extends StatefulWidget {
  const ApprovedStoreRequestsPage({super.key});

  @override
  State<ApprovedStoreRequestsPage> createState() =>
      _ApprovedStoreRequestsPageState();
}

class _ApprovedStoreRequestsPageState extends State<ApprovedStoreRequestsPage> {
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
          await _networkClient.get('/store-requests/status/APPROVED');
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
        title: const Text('Approved'),
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
      final cs = Theme.of(context).colorScheme;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 56, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 14),
            Text('No approved requests',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return _ApprovedCard(
          request: request,
          onRefresh: _loadRequests,
          onOpenChat: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoreChatPage(
                storeRequestId: request.id,
                myRole: 'STORE',
                title: 'Chat with Staff',
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ApprovedCard extends StatelessWidget {
  final StoreRequest request;
  final VoidCallback onRefresh;
  final VoidCallback onOpenChat;

  const _ApprovedCard({
    required this.request,
    required this.onRefresh,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const accent = Color(0xFF89B4FA); // blue for approved

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
                    child: const Icon(Icons.check_circle_rounded,
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
            if (request.responseComment != null &&
                request.responseComment!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.comment_rounded,
                          size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
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
            Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpenChat,
                      icon: const Icon(Icons.chat_rounded, size: 16),
                      label: const Text('Chat', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showFulfillDialog(context, request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA6E3A1),
                        foregroundColor: Colors.black87,
                      ),
                      icon: const Icon(Icons.done_all_rounded, size: 16),
                      label:
                          const Text('Fulfill', style: TextStyle(fontSize: 13)),
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

  Future<void> _showFulfillDialog(
      BuildContext context, StoreRequest request) async {
    final commentController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Fulfilled'),
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
              decoration: const InputDecoration(
                labelText: 'Fulfillment Notes',
                hintText: 'Items delivered to staff member...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA6E3A1),
                foregroundColor: Colors.black87),
            child: const Text('Mark Fulfilled'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final networkClient = NetworkClient();
        await networkClient
            .post('/store-requests/${request.id}/respond', data: {
          'status': 'FULFILLED',
          'response_comment': commentController.text.isEmpty
              ? 'Items delivered'
              : commentController.text,
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marked as fulfilled')),
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
