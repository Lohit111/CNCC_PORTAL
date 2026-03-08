import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:ticket_management_app/core/network/network_client.dart';
import 'package:ticket_management_app/domain/entities/request_entity.dart';
import 'package:ticket_management_app/presentation/pages/admin/manage_roles_page.dart';
import 'package:ticket_management_app/presentation/pages/admin/manage_types_page.dart';
import 'package:ticket_management_app/presentation/pages/admin/manage_assignments_page.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  final _networkClient = NetworkClient();
  List<Request> _requests = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

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
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await fb.FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.category),
            label: 'Types',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment),
            label: 'Assignments',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildRequestsTab();
      case 1:
        return _buildUsersTab();
      case 2:
        return _buildTypesTab();
      case 3:
        return _buildAssignmentsTab();
      default:
        return _buildRequestsTab();
    }
  }

  Widget _buildRequestsTab() {
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
            Text('No requests found'),
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
          child: ListTile(
            title: Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Status: ${request.status}\nID: ${request.id.substring(0, 8)}...',
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'assign',
                  child: Text('Assign to Staff'),
                ),
                const PopupMenuItem(
                  value: 'update',
                  child: Text('Update Status'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'assign':
                    _showAssignStaffDialog(request);
                    break;
                  case 'update':
                    _showUpdateStatusDialog(request);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(request);
                    break;
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAssignStaffDialog(Request request) async {
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

      showDialog(
        context: context,
        builder: (context) => _AssignStaffDialog(
          request: request,
          staffList: staffList,
          onAssigned: _loadRequests,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading staff: $e')),
        );
      }
    }
  }

  void _showUpdateStatusDialog(Request request) {
    showDialog(
      context: context,
      builder: (context) => _UpdateStatusDialog(
        request: request,
        onUpdated: _loadRequests,
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Request request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: const Text('Are you sure you want to delete this request? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _networkClient.delete('/requests/${request.id}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request deleted successfully')),
          );
          _loadRequests();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting request: $e')),
          );
        }
      }
    }
  }

  Widget _buildUsersTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('User & Role Management'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageRolesPage(),
                ),
              );
            },
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('Manage Roles'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.category, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Request Types'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageTypesPage(),
                ),
              );
            },
            icon: const Icon(Icons.category),
            label: const Text('Manage Types'),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Assignments'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageAssignmentsPage(),
                ),
              );
            },
            icon: const Icon(Icons.assignment_ind),
            label: const Text('Manage Assignments'),
          ),
        ],
      ),
    );
  }
}

class _AssignStaffDialog extends StatefulWidget {
  final Request request;
  final List<dynamic> staffList;
  final VoidCallback onAssigned;

  const _AssignStaffDialog({
    required this.request,
    required this.staffList,
    required this.onAssigned,
  });

  @override
  State<_AssignStaffDialog> createState() => _AssignStaffDialogState();
}

class _AssignStaffDialogState extends State<_AssignStaffDialog> {
  final _networkClient = NetworkClient();
  String? _selectedStaffId;
  bool _isLoading = false;

  Future<void> _assignStaff() async {
    if (_selectedStaffId == null) return;

    setState(() => _isLoading = true);

    try {
      await _networkClient.post('/assignments/', data: {
        'request_id': widget.request.id,
        'staff_id': _selectedStaffId,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff assigned successfully')),
        );
        widget.onAssigned();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning staff: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign to Staff'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request: ${widget.request.description}'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select Staff Member',
              border: OutlineInputBorder(),
            ),
            value: _selectedStaffId,
            items: widget.staffList.map((staff) {
              return DropdownMenuItem<String>(
                value: staff['id'],
                child: Text(staff['email']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedStaffId = value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _assignStaff,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Assign'),
        ),
      ],
    );
  }
}

class _UpdateStatusDialog extends StatefulWidget {
  final Request request;
  final VoidCallback onUpdated;

  const _UpdateStatusDialog({
    required this.request,
    required this.onUpdated,
  });

  @override
  State<_UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends State<_UpdateStatusDialog> {
  final _networkClient = NetworkClient();
  String? _selectedStatus;
  bool _isLoading = false;

  final List<String> _statuses = [
    'RAISED',
    'ASSIGNED',
    'IN_PROGRESS',
    'COMPLETED',
    'REJECTED',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.request.status;
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null || _selectedStatus == widget.request.status) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _networkClient.put('/requests/${widget.request.id}', data: {
        'status': _selectedStatus,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully')),
        );
        widget.onUpdated();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request: ${widget.request.description}'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            value: _selectedStatus,
            items: _statuses.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedStatus = value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateStatus,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}
