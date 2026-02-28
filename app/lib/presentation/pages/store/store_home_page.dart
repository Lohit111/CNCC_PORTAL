import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:ticket_management_app/core/network/network_client.dart';
import 'package:ticket_management_app/domain/entities/store_request_entity.dart';

class StoreHomePage extends ConsumerStatefulWidget {
  const StoreHomePage({super.key});

  @override
  ConsumerState<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends ConsumerState<StoreHomePage> {
  final _networkClient = NetworkClient();
  List<StoreRequest> _storeRequests = [];
  bool _isLoading = true;
  String _selectedStatus = 'PENDING';

  @override
  void initState() {
    super.initState();
    _loadStoreRequests();
  }

  Future<void> _loadStoreRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await _networkClient.get(
        '/store-requests/status/$_selectedStatus',
      );

      final data = response.data;
      setState(() {
        _storeRequests = (data['items'] as List)
            .map((json) => StoreRequest.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _respondToRequest(
    String requestId,
    String status,
    String? comment,
  ) async {
    try {
      await _networkClient.post(
        '/store-requests/$requestId/respond',
        data: {
          'status': status,
          if (comment != null) 'response_comment': comment,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Response sent successfully')),
        );
        _loadStoreRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showRespondDialog(StoreRequest request) {
    final commentController = TextEditingController();
    String selectedStatus = 'APPROVED';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Respond to Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'APPROVED', child: Text('Approve')),
                  DropdownMenuItem(value: 'REJECTED', child: Text('Reject')),
                  DropdownMenuItem(
                      value: 'FULFILLED', child: Text('Fulfilled')),
                ],
                onChanged: (value) {
                  setDialogState(() => selectedStatus = value!);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _respondToRequest(
                  request.id,
                  selectedStatus,
                  commentController.text.isEmpty
                      ? null
                      : commentController.text,
                );
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStoreRequests,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await fb.FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'PENDING',
                  label: Text('Pending'),
                  icon: Icon(Icons.pending),
                ),
                ButtonSegment(
                  value: 'APPROVED',
                  label: Text('Approved'),
                  icon: Icon(Icons.check),
                ),
                ButtonSegment(
                  value: 'FULFILLED',
                  label: Text('Fulfilled'),
                  icon: Icon(Icons.done_all),
                ),
              ],
              selected: {_selectedStatus},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedStatus = newSelection.first;
                  _loadStoreRequests();
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _storeRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text('No $_selectedStatus requests'),
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
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (request.responseComment != null) ...[
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Response:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(request.responseComment!),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      if (request.status == 'PENDING')
                                        ElevatedButton(
                                          onPressed: () =>
                                              _showRespondDialog(request),
                                          child: const Text('Respond'),
                                        ),
                                      if (request.status == 'APPROVED')
                                        ElevatedButton.icon(
                                          onPressed: () => _respondToRequest(
                                            request.id,
                                            'FULFILLED',
                                            'Items delivered',
                                          ),
                                          icon: const Icon(Icons.done_all),
                                          label:
                                              const Text('Mark as Fulfilled'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
