import 'package:flutter/material.dart';
import 'package:ticket_management_app/core/network/network_client.dart';
import 'package:ticket_management_app/domain/entities/request_entity.dart';
import 'package:ticket_management_app/presentation/pages/user/request_detail_page.dart';

class CompletedRequestsUserPage extends StatefulWidget {
  const CompletedRequestsUserPage({super.key});

  @override
  State<CompletedRequestsUserPage> createState() => _CompletedRequestsUserPageState();
}

class _CompletedRequestsUserPageState extends State<CompletedRequestsUserPage> {
  final _networkClient = NetworkClient();
  List<Request> _requests = [];
  bool _isLoading = true;
  String _filter = 'ALL'; // ALL, COMPLETED, REJECTED

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
            .where((req) => req.status == 'COMPLETED' || req.status == 'REJECTED')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Request> get _filteredRequests {
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
            label: const Text('Completed'),
            selected: _filter == 'COMPLETED',
            onSelected: (selected) {
              setState(() => _filter = 'COMPLETED');
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
          child: ListTile(
            leading: Icon(
              request.status == 'COMPLETED' ? Icons.check_circle : Icons.cancel,
              color: request.status == 'COMPLETED' ? Colors.green : Colors.red,
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
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RequestDetailPage(
                    requestId: request.id,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
