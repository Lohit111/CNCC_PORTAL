import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/authenticated_user_provider.dart';
import '../../../core/network/api_service.dart';
import '../../../core/models/store_request_model.dart';

class StoreHomeScreen extends ConsumerStatefulWidget {
  const StoreHomeScreen({super.key});

  @override
  ConsumerState<StoreHomeScreen> createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends ConsumerState<StoreHomeScreen> {
  final ApiService _apiService = ApiService();
  List<StoreRequestModel> _requests = [];
  bool _isLoading = false;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await _apiService.getAllStoreRequests(
        statusFilter: _statusFilter,
      );
      setState(() => _requests = requests);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveRequest(String requestId) async {
    final comment = await _showCommentDialog('Approve Request');
    if (comment != null) {
      try {
        await _apiService.approveEquipmentRequest(requestId, comment);
        _loadRequests();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request approved')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final comment = await _showCommentDialog('Reject Request');
    if (comment != null) {
      try {
        await _apiService.rejectEquipmentRequest(requestId, comment);
        _loadRequests();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request rejected')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<String?> _showCommentDialog(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter comment'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Requests'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _statusFilter = value == 'ALL' ? null : value;
              });
              _loadRequests();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'ALL', child: Text('All')),
              const PopupMenuItem(value: 'PENDING', child: Text('Pending')),
              const PopupMenuItem(value: 'APPROVED', child: Text('Approved')),
              const PopupMenuItem(value: 'REJECTED', child: Text('Rejected')),
              const PopupMenuItem(value: 'FULFILLED', child: Text('Fulfilled')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authenticatedUserProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRequests,
              child: _requests.isEmpty
                  ? const Center(child: Text('No equipment requests'))
                  : ListView.builder(
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final request = _requests[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(request.description),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('By: ${request.requesterEmail ?? 'Unknown'}'),
                                Text(
                                  'Status: ${request.status}',
                                  style: TextStyle(
                                    color: _getStatusColor(request.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: request.status == 'PENDING'
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check,
                                            color: Colors.green),
                                        onPressed: () =>
                                            _approveRequest(request.id),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _rejectRequest(request.id),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'FULFILLED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
