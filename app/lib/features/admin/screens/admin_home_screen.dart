import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/authenticated_user_provider.dart';
import '../../../core/network/api_service.dart';
import '../../../core/models/request_model.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  final ApiService _apiService = ApiService();
  List<RequestModel> _requests = [];
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
      final response = await _apiService.getAllRequests(
        statusFilter: _statusFilter,
      );
      final items = response['items'] as List;
      setState(() {
        _requests = items.map((json) => RequestModel.fromJson(json)).toList();
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
              const PopupMenuItem(value: 'RAISED', child: Text('Raised')),
              const PopupMenuItem(value: 'ASSIGNED', child: Text('Assigned')),
              const PopupMenuItem(
                value: 'REASSIGN_REQUESTED',
                child: Text('Reassign Requested'),
              ),
              const PopupMenuItem(value: 'COMPLETED', child: Text('Completed')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to admin settings
            },
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
                  ? const Center(child: Text('No requests'))
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
                            title: Text(request.mainTypeName ?? 'Request'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('By: ${request.raiserEmail ?? 'Unknown'}'),
                                Text(
                                  'Status: ${request.status}',
                                  style: TextStyle(
                                    color: _getStatusColor(request.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _formatDate(request.createdAt),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '${request.commentsCount ?? 0} comments',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                            onTap: () {
                              // Navigate to request detail with admin actions
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'RAISED':
        return Colors.blue;
      case 'REJECTED':
        return Colors.red;
      case 'REPLIED':
        return Colors.orange;
      case 'ASSIGNED':
        return Colors.purple;
      case 'IN_PROGRESS':
        return Colors.amber;
      case 'REASSIGN_REQUESTED':
        return Colors.deepOrange;
      case 'COMPLETED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
