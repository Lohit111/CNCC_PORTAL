import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_request_detail_page.dart';

class AssignedRequestsPage extends StatefulWidget {
  const AssignedRequestsPage({super.key});

  @override
  State<AssignedRequestsPage> createState() => _AssignedRequestsPageState();
}

class _AssignedRequestsPageState extends State<AssignedRequestsPage> {
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
      final response = await _networkClient.get('/requests/');
      final data = response.data;
      setState(() {
        _requests = (data['items'] as List)
            .map((json) => Request.fromJson(json))
            .where((req) =>
                (req.status == 'ASSIGNED' ||
                    req.status == 'IN_PROGRESS' ||
                    req.status == 'REASSIGN_REQUESTED') &&
                req.isActive == 'true')
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assigned Requests'),
            Text(
              'Being worked on by staff',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
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
            Text('No assigned requests'),
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
            leading: Icon(
              _getIconForStatus(request.status),
              color: _getColorForStatus(request.status),
            ),
            title: Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Status: ${request.statusDisplayText}\nID: ${request.id.substring(0, 8)}...',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Full Description: ${request.description}'),
                    const SizedBox(height: 16),
                    if (request.status == 'REASSIGN_REQUESTED')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.pink),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.pink),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Staff has requested reassignment',
                                  style: TextStyle(color: Colors.pink),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (request.status != 'REASSIGN_REQUESTED')
                          ElevatedButton.icon(
                            onPressed: () => _viewAssignments(request),
                            icon: const Icon(Icons.people),
                            label: const Text('View Staff'),
                          ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminRequestDetailPage(
                                    requestId: request.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.timeline),
                          label: const Text('Timeline'),
                        ),
                        if (request.status == 'REASSIGN_REQUESTED')
                          ElevatedButton.icon(
                            onPressed: () => _reassignStaff(request),
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Reassign'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                      ],
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

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'ASSIGNED':
        return Icons.person_add;
      case 'IN_PROGRESS':
        return Icons.work;
      case 'REASSIGN_REQUESTED':
        return Icons.swap_horiz;
      default:
        return Icons.circle;
    }
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'ASSIGNED':
        return Colors.purple;
      case 'IN_PROGRESS':
        return Colors.amber;
      case 'REASSIGN_REQUESTED':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  Future<void> _viewAssignments(Request request) async {
    try {
      final response =
          await _networkClient.get('/assignments/request/${request.id}');

      // Keep only active assignments
      final activeAssignments =
          (response.data as List).where((a) => a['is_active'] == true).toList();

      // Bulk-fetch staff emails — one request
      final Map<String, String> staffEmails = {};
      final ids = activeAssignments
          .map((a) => a['staff_id'] as String)
          .toSet()
          .toList();
      if (ids.isNotEmpty) {
        try {
          final queryParams = ids.map((id) => 'ids=$id').join('&');
          final res = await _networkClient.get('/users/emails?$queryParams');
          if (res.data is Map) {
            (res.data as Map).forEach((k, v) {
              staffEmails[k.toString()] = v.toString();
            });
          }
        } catch (_) {}
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Assigned Staff'),
          content: activeAssignments.isEmpty
              ? const Text('No active staff assigned.')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: activeAssignments.length,
                    itemBuilder: (context, index) {
                      final assignment = activeAssignments[index];
                      final staffId = assignment['staff_id'] as String;
                      final email = staffEmails[staffId] ?? 'Unknown';
                      return ListTile(
                        leading: const Icon(Icons.person, color: Colors.green),
                        title: Text(email),
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
          SnackBar(content: Text('Error loading assignments: $e')),
        );
      }
    }
  }

  Future<void> _reassignStaff(Request request) async {
    try {
      // Fetch users and roles
      final usersResponse = await _networkClient.get('/users/');
      final rolesResponse = await _networkClient.get('/roles/');

      final users = usersResponse.data['items'] as List;
      final roles = rolesResponse.data['items'] as List;

      // Match users with STAFF role
      final staffList = users.where((user) {
        final role = roles.firstWhere(
          (r) => r['email'] == user['email'],
          orElse: () => null,
        );
        return role != null && role['role'] == 'STAFF';
      }).toList();

      if (!mounted) return;

      final Set<String> selectedIds = {};

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Reassign to Staff'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Select one or more staff members:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: staffList.isEmpty
                        ? const Text('No staff members available.')
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: staffList.length,
                            itemBuilder: (context, index) {
                              final staff = staffList[index];
                              final id = staff['id'] as String;
                              return CheckboxListTile(
                                dense: true,
                                title: Text(staff['email'] as String),
                                value: selectedIds.contains(id),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      selectedIds.add(id);
                                    } else {
                                      selectedIds.remove(id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  if (selectedIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${selectedIds.length} selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedIds.isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
                child: const Text('Reassign'),
              ),
            ],
          ),
        ),
      );

      if (confirmed == true && selectedIds.isNotEmpty) {
        await _networkClient.post('/assignments/bulk', data: {
          'request_id': request.id,
          'staff_ids': selectedIds.toList(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${selectedIds.length} staff member(s) reassigned successfully'),
            ),
          );
          _loadRequests();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reassigning staff: $e')),
        );
      }
    }
  }
}
