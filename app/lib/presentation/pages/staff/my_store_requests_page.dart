import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticket_management_app/core/network/network_client.dart';
import 'package:ticket_management_app/domain/entities/store_request_entity.dart';
import 'package:ticket_management_app/presentation/providers/auth_provider.dart';

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

      // Filter by current user
      final user = ref.read(authProvider).user;
      final allRequests = (data['items'] as List)
          .map((json) => StoreRequest.fromJson(json))
          .toList();

      setState(() {
        _storeRequests =
            allRequests.where((req) => req.requestedBy == user?.id).toList();
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
                                _buildInfoRow('Parent Request',
                                    request.parentRequestId.substring(0, 8)),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                    'Created', _formatDate(request.createdAt)),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                    'Updated', _formatDate(request.updatedAt)),
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
                                if (request.status == 'APPROVED') ...[
                                  const Divider(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () => _openChat(request),
                                    icon: const Icon(Icons.chat),
                                    label: const Text('Chat with Store'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                    ),
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

  Future<void> _openChat(StoreRequest request) async {
    try {
      final response = await _networkClient.get('/store-requests/${request.id}/chat');
      final chats = response.data as List;

      if (!mounted) return;

      final messageController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Chat with Store'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final isMe = chat['sender_role'] == 'STAFF';
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            constraints: const BoxConstraints(maxWidth: 250),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chat['message'],
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  chat['sender_role'],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          if (messageController.text.isEmpty) return;
                          
                          try {
                            await _networkClient.post(
                              '/store-requests/${request.id}/chat',
                              data: {'message': messageController.text},
                            );
                            messageController.clear();
                            
                            // Reload chat
                            final newResponse = await _networkClient.get(
                              '/store-requests/${request.id}/chat',
                            );
                            setDialogState(() {
                              chats.clear();
                              chats.addAll(newResponse.data as List);
                            });
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat: $e')),
        );
      }
    }
  }
}
