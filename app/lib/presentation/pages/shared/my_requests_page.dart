import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/presentation/pages/user/request_detail_page.dart';

/// Reusable "My Requests" page for STAFF and ADMIN roles.
/// Shows requests raised by the current user with filtering by status group.
class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => MyRequestsPageState();
}

class MyRequestsPageState extends State<MyRequestsPage> {
  final _networkClient = NetworkClient();
  List<Request> _requests = [];
  bool _isLoading = true;

  // Filter: 'active' | 'needs_response' | 'completed' | 'rejected'
  String _filter = 'active';

  void refresh() => _loadRequests();

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await _networkClient.get('/users/requests');
      final data = response.data;
      setState(() {
        _requests = (data['items'] as List)
            .map((json) => Request.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Request> get _filteredRequests {
    switch (_filter) {
      case 'active':
        return _requests
            .where((r) =>
                r.status != 'COMPLETED' &&
                r.status != 'REJECTED' &&
                r.status != 'REPLIED')
            .toList();
      case 'needs_response':
        return _requests.where((r) => r.status == 'REPLIED').toList();
      case 'completed':
        return _requests.where((r) => r.status == 'COMPLETED').toList();
      case 'rejected':
        return _requests.where((r) => r.status == 'REJECTED').toList();
      default:
        return _requests;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('active', 'Active', Icons.pending_actions),
            const SizedBox(width: 8),
            _filterChip('needs_response', 'Needs Response', Icons.reply,
                badge: true),
            const SizedBox(width: 8),
            _filterChip('completed', 'Completed', Icons.check_circle),
            const SizedBox(width: 8),
            _filterChip('rejected', 'Rejected', Icons.cancel),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label, IconData icon,
      {bool badge = false}) {
    final isSelected = _filter == value;
    final count = _countForFilter(value);
    return FilterChip(
      avatar: Icon(icon,
          size: 16,
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.primary),
      label: Text(count > 0 ? '$label ($count)' : label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.onPrimary : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }

  int _countForFilter(String filter) {
    switch (filter) {
      case 'active':
        return _requests
            .where((r) =>
                r.status != 'COMPLETED' &&
                r.status != 'REJECTED' &&
                r.status != 'REPLIED')
            .length;
      case 'needs_response':
        return _requests.where((r) => r.status == 'REPLIED').length;
      case 'completed':
        return _requests.where((r) => r.status == 'COMPLETED').length;
      case 'rejected':
        return _requests.where((r) => r.status == 'REJECTED').length;
      default:
        return 0;
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filteredRequests;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_emptyIcon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_emptyMessage,
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            if (_filter == 'active')
              const Text(
                'Use the + button to raise a new request',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final request = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              _getStatusIcon(request.status),
              color: _getStatusColor(request.status),
              size: 32,
            ),
            title: Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${request.statusDisplayText}\n${_formatDate(request.createdAt)}',
            ),
            trailing: request.status == 'REPLIED'
                ? const Chip(
                    label: Text('Action Required'),
                    backgroundColor: Colors.orange,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                  )
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RequestDetailPage(requestId: request.id),
                ),
              ).then((_) => _loadRequests());
            },
          ),
        );
      },
    );
  }

  IconData get _emptyIcon {
    switch (_filter) {
      case 'needs_response':
        return Icons.mark_email_read;
      case 'completed':
        return Icons.task_alt;
      case 'rejected':
        return Icons.do_not_disturb;
      default:
        return Icons.inbox;
    }
  }

  String get _emptyMessage {
    switch (_filter) {
      case 'needs_response':
        return 'No requests need your response';
      case 'completed':
        return 'No completed requests';
      case 'rejected':
        return 'No rejected requests';
      default:
        return 'No active requests';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'RAISED':
        return Icons.new_releases;
      case 'REPLIED':
        return Icons.reply;
      case 'ASSIGNED':
        return Icons.assignment_ind;
      case 'IN_PROGRESS':
        return Icons.pending;
      case 'COMPLETED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      case 'REASSIGN_REQUESTED':
        return Icons.swap_horiz;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
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
      case 'REJECTED':
        return Colors.red;
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
