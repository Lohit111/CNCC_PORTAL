import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/store_request_entity.dart';

class FulfilledRejectedPage extends StatefulWidget {
  const FulfilledRejectedPage({super.key});

  @override
  State<FulfilledRejectedPage> createState() => _FulfilledRejectedPageState();
}

class _FulfilledRejectedPageState extends State<FulfilledRejectedPage> {
  final _networkClient = NetworkClient();
  List<StoreRequest> _requests = [];
  bool _isLoading = true;
  String _filter = 'ALL'; // ALL, FULFILLED, REJECTED

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      // Load both FULFILLED and REJECTED
      final fulfilledResponse =
          await _networkClient.get('/store-requests/status/FULFILLED');
      final rejectedResponse =
          await _networkClient.get('/store-requests/status/REJECTED');

      final fulfilled = (fulfilledResponse.data['items'] as List)
          .map((json) => StoreRequest.fromJson(json))
          .toList();
      final rejected = (rejectedResponse.data['items'] as List)
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

  List<StoreRequest> get _filteredRequests {
    if (_filter == 'ALL') return _requests;
    return _requests.where((req) => req.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _filter == 'ALL',
            onSelected: (selected) {
              setState(() => _filter = 'ALL');
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Fulfilled'),
            selected: _filter == 'FULFILLED',
            onSelected: (selected) {
              setState(() => _filter = 'FULFILLED');
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Rejected'),
            selected: _filter == 'REJECTED',
            onSelected: (selected) {
              setState(() => _filter = 'REJECTED');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredRequests = _filteredRequests;

    if (filteredRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No ${_filter.toLowerCase()} requests'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRequests.length,
      itemBuilder: (context, index) {
        final request = filteredRequests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Icon(
              request.status == 'FULFILLED' ? Icons.done_all : Icons.cancel,
              color: request.status == 'FULFILLED' ? Colors.green : Colors.red,
            ),
            title: Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${request.status}\nParent: ${request.parentRequestId.substring(0, 8)}...',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Full Description: ${request.description}'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Created', _formatDate(request.createdAt)),
                    const SizedBox(height: 4),
                    _buildInfoRow('Updated', _formatDate(request.updatedAt)),
                    if (request.responseComment != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: request.status == 'FULFILLED'
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.status == 'FULFILLED'
                                  ? 'Fulfillment Notes:'
                                  : 'Rejection Reason:',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(request.responseComment!),
                          ],
                        ),
                      ),
                    ],
                    if (request.status == 'FULFILLED') ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _viewChat(request),
                        icon: const Icon(Icons.chat),
                        label: const Text('View Chat History'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

  Future<void> _viewChat(StoreRequest request) async {
    try {
      final response =
          await _networkClient.get('/store-requests/${request.id}/chat');
      final chats = response.data as List;

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chat History'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: chats.isEmpty
                ? const Center(child: Text('No chat messages'))
                : ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final isStore = chat['sender_role'] == 'STORE';
                      return Align(
                        alignment: isStore
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isStore
                                ? Colors.green.shade100
                                : Colors.blue.shade100,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
