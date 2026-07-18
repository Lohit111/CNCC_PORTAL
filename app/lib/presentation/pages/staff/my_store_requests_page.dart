import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/store_request_entity.dart';
import 'package:cncc_portal/presentation/pages/shared/store_chat_page.dart';
import 'package:cncc_portal/presentation/providers/auth_provider.dart';

class MyStoreRequestsPage extends ConsumerStatefulWidget {
  const MyStoreRequestsPage({super.key});

  @override
  ConsumerState<MyStoreRequestsPage> createState() =>
      _MyStoreRequestsPageState();
}

class _MyStoreRequestsPageState extends ConsumerState<MyStoreRequestsPage> {
  final _networkClient = NetworkClient();
  List<StoreRequest> _storeRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreRequests();
  }

  Future<void> _loadStoreRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await _networkClient.get('/store-requests/');
      final data = response.data;
      final user = ref.read(authProvider).user;
      final all = (data['items'] as List)
          .map((json) => StoreRequest.fromJson(json))
          .toList();

      setState(() {
        _storeRequests =
            all.where((req) => req.requestedBy == user?.id).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStoreRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _storeRequests.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _storeRequests.length,
                  itemBuilder: (context, index) => _StoreRequestCard(
                    request: _storeRequests[index],
                    onOpenChat: (req) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoreChatPage(
                          storeRequestId: req.id,
                          myRole: 'STAFF',
                          title: 'Chat with Store',
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_rounded,
              size: 56, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 14),
          Text('No store requests yet',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

class _StoreRequestCard extends StatelessWidget {
  final StoreRequest request;
  final void Function(StoreRequest) onOpenChat;

  const _StoreRequestCard({required this.request, required this.onOpenChat});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _statusColor(request.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
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
                    child: Icon(_statusIcon(request.status),
                        color: color, size: 20),
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
                                  color: cs.onSurface.withValues(alpha: 0.4)),
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
                      Icon(Icons.store_rounded,
                          size: 13, color: cs.onSurface.withValues(alpha: 0.4)),
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
            if (request.status == 'APPROVED') ...[
              Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => onOpenChat(request),
                    icon: const Icon(Icons.chat_rounded, size: 16),
                    label: const Text('Chat with Store',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFF9E2AF);
      case 'APPROVED':
        return const Color(0xFF89B4FA);
      case 'REJECTED':
        return const Color(0xFFF38BA8);
      case 'FULFILLED':
        return const Color(0xFFA6E3A1);
      default:
        return const Color(0xFF6C7086);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.pending_rounded;
      case 'APPROVED':
        return Icons.check_circle_rounded;
      case 'REJECTED':
        return Icons.cancel_rounded;
      case 'FULFILLED':
        return Icons.done_all_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
