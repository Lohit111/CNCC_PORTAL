import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/authenticated_user_provider.dart';
import '../../../core/network/api_service.dart';
import '../../../core/models/request_model.dart';

class StaffHomeScreen extends ConsumerStatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  ConsumerState<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends ConsumerState<StaffHomeScreen> {
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
      final response = await _apiService.getAssignedRequests();
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

  Future<void> _startRequest(String requestId) async {
    try {
      await _apiService.startRequest(requestId);
      _loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request started')),
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

  Future<void> _completeRequest(String requestId) async {
    try {
      await _apiService.completeRequest(requestId);
      _loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request completed')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory),
            onPressed: () {
              // Navigate to equipment requests
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
                  ? const Center(child: Text('No assigned requests'))
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
                            trailing: _buildActionButton(request),
                            onTap: () {
                              // Navigate to request detail
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget? _buildActionButton(RequestModel request) {
    if (request.status == 'ASSIGNED') {
      return ElevatedButton(
        onPressed: () => _startRequest(request.id),
        child: const Text('Start'),
      );
    } else if (request.status == 'IN_PROGRESS') {
      return ElevatedButton(
        onPressed: () => _completeRequest(request.id),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        child: const Text('Complete'),
      );
    }
    return null;
  }

  Color _getStatusColor(String status) {
    switch (status) {
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
}
