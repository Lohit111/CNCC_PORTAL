import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticket_management_app/core/network/network_client.dart';
import 'package:ticket_management_app/domain/entities/request_entity.dart';
import 'package:ticket_management_app/domain/entities/track_entity.dart';
import 'package:ticket_management_app/presentation/providers/auth_provider.dart';

class CompletedByMePage extends ConsumerStatefulWidget {
  const CompletedByMePage({super.key});

  @override
  ConsumerState<CompletedByMePage> createState() => _CompletedByMePageState();
}

class _CompletedByMePageState extends ConsumerState<CompletedByMePage> {
  final _networkClient = NetworkClient();
  List<Request> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;

      // Get my assignments (including inactive ones)
      final assignmentsResponse = await _networkClient.get(
        '/assignments/staff/${user.id}',
        queryParameters: {'active_only': false},
      );
      final assignments = assignmentsResponse.data as List;

      // Get all requests
      final requestsResponse = await _networkClient.get('/requests/');
      final allRequests = (requestsResponse.data['items'] as List)
          .map((json) => Request.fromJson(json))
          .toList();

      // Filter requests that were assigned to me and are now completed
      final assignedRequestIds = assignments.map((a) => a['request_id']).toSet();
      setState(() {
        _requests = allRequests
            .where((req) =>
                assignedRequestIds.contains(req.id) &&
                req.status == 'COMPLETED')
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
        title: const Text('Completed by Me'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No completed requests'),
            SizedBox(height: 8),
            Text(
              'Requests you complete will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Completed\n${_formatDate(request.updatedAt)}',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Full Description: ${request.description}'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _viewTimeline(request),
                      icon: const Icon(Icons.timeline),
                      label: const Text('View Timeline'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _viewTimeline(Request request) async {
    try {
      final response = await _networkClient.get('/requests/${request.id}/comments');
      final tracks = (response.data as List)
          .map((json) => Track.fromJson(json))
          .toList();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Request Timeline'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      _getIconForAction(track.actionType),
                      color: _getColorForAction(track.actionType),
                    ),
                    title: Text(track.actionDisplayText),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('By: ${track.performedByRole}'),
                        if (track.comment != null)
                          Text(
                            'Comment: ${track.comment}',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        Text(
                          track.createdAt.toString().substring(0, 19),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
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
          SnackBar(content: Text('Error loading timeline: $e')),
        );
      }
    }
  }

  IconData _getIconForAction(String actionType) {
    switch (actionType) {
      case 'RAISED':
        return Icons.add_circle;
      case 'REPLIED':
        return Icons.reply;
      case 'ASSIGNED':
        return Icons.person_add;
      case 'IN_PROGRESS':
        return Icons.work;
      case 'COMPLETED':
        return Icons.check_circle;
      case 'REASSIGN_REQUESTED':
        return Icons.swap_horiz;
      default:
        return Icons.circle;
    }
  }

  Color _getColorForAction(String actionType) {
    switch (actionType) {
      case 'RAISED':
        return Colors.blue;
      case 'REPLIED':
        return Colors.orange;
      case 'ASSIGNED':
        return Colors.purple;
      case 'IN_PROGRESS':
        return Colors.amber;
      case 'COMPLETED':
        return Colors.green;
      case 'REASSIGN_REQUESTED':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
