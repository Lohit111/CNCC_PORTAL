import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticket_management_app/core/network/network_client.dart';
import 'package:ticket_management_app/domain/entities/store_request_entity.dart';
import 'package:ticket_management_app/presentation/providers/auth_provider.dart';

class MyStoreRequestsPage extends ConsumerStatefulWidget {
  const MyStoreRequestsPage({super.key});

  @override
  ConsumerState<MyStoreRequestsPage> createState() => _MyStoreRequestsPageState();
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
      
      // Filter by current user
      final user = ref.read(authProvider).user;
      final allRequests = (data['items'] as List)
          .map((json) => StoreRequest.fromJson(json))
          .toList();
      
      setState(() {
        _storeRequests = allRequests
            .where((req) => req.requestedBy == user?.id)
            .toList();
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
        title: const Text('My Store Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStoreRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _storeRequests.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No store requests yet'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _storeRequests.length,
                  itemBuilder: (context, index) {
                    final request = _storeRequests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text(
                          request.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Status: ${request.status}\n${_formatDate(request.createdAt)}',
                        ),
                        trailing: _getStatusChip(request.status),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildInfoRow('Parent Request', request.parentRequestId.substring(0, 8)),
                                const SizedBox(height: 8),
                                _buildInfoRow('Created', _formatDate(request.createdAt)),
                                const SizedBox(height: 8),
                                _buildInfoRow('Updated', _formatDate(request.updatedAt)),
                                if (request.responseComment != null) ...[
                                  const Divider(height: 24),
                                  const Text(
                                    'Store Response:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(request.responseComment!),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Text(value),
      ],
    );
  }

  Widget _getStatusChip(String status) {
    Color color;
    switch (status) {
      case 'PENDING':
        color = Colors.orange;
        break;
      case 'APPROVED':
        color = Colors.blue;
        break;
      case 'REJECTED':
        color = Colors.red;
        break;
      case 'FULFILLED':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
