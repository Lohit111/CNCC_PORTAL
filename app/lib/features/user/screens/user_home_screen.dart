import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/authenticated_user_provider.dart';
import '../../../core/network/api_service.dart';
import '../../../core/models/request_model.dart';

class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends ConsumerState<UserHomeScreen> {
  final ApiService _apiService = ApiService();
  List<RequestModel> _requests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getMyRequests();
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
        title: const Text('My Requests'),
        actions: [
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
                  ? const Center(child: Text('No requests yet'))
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
                                Text(request.subTypeName ?? ''),
                                Text(
                                  'Status: ${request.status}',
                                  style: TextStyle(
                                    color: _getStatusColor(request.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              _formatDate(request.createdAt),
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              // Navigate to request detail
                            },
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create request screen
        },
        child: const Icon(Icons.add),
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
