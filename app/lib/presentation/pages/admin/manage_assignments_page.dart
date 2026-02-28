import 'package:flutter/material.dart';
import 'package:ticket_management_app/core/network/network_client.dart';
import 'package:ticket_management_app/domain/entities/assignment_entity.dart';
import 'package:ticket_management_app/domain/entities/user_entity.dart';

class ManageAssignmentsPage extends StatefulWidget {
  const ManageAssignmentsPage({super.key});

  @override
  State<ManageAssignmentsPage> createState() => _ManageAssignmentsPageState();
}

class _ManageAssignmentsPageState extends State<ManageAssignmentsPage> {
  final _networkClient = NetworkClient();
  List<User> _staffUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load all users to filter staff
      final usersResponse = await _networkClient.get('/users/');
      final users = (usersResponse.data['items'] as List)
          .map((json) => User.fromJson(json))
          .where((user) => user.role == 'STAFF')
          .toList();

      setState(() {
        _staffUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateAssignmentDialog() {
    final requestIdController = TextEditingController();
    User? selectedStaff;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Assignment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: requestIdController,
                decoration: const InputDecoration(
                  labelText: 'Request ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<User>(
                initialValue: selectedStaff,
                decoration: const InputDecoration(
                  labelText: 'Assign to Staff',
                  border: OutlineInputBorder(),
                ),
                items: _staffUsers.map((user) {
                  return DropdownMenuItem(
                    value: user,
                    child: Text(user.email),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() => selectedStaff = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedStaff == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select a staff member')),
                  );
                  return;
                }

                try {
                  await _networkClient.post('/assignments/', data: {
                    'request_id': requestIdController.text,
                    'staff_id': selectedStaff!.id,
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Assignment created')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStaffAssignments(User staff) async {
    try {
      final response = await _networkClient.get(
        '/assignments/staff/${staff.id}',
        queryParameters: {'active_only': false},
      );

      final assignments = (response.data as List)
          .map((json) => Assignment.fromJson(json))
          .toList();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${staff.email} Assignments'),
          content: SizedBox(
            width: double.maxFinite,
            child: assignments.isEmpty
                ? const Center(child: Text('No assignments'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: assignments.length,
                    itemBuilder: (context, index) {
                      final assignment = assignments[index];
                      return ListTile(
                        title: Text(
                            'Request: ${assignment.requestId.substring(0, 8)}...'),
                        subtitle: Text(
                          'Status: ${assignment.isActive ? "Active" : "Inactive"}',
                        ),
                        trailing: assignment.isActive
                            ? const Chip(
                                label: Text('Active'),
                                backgroundColor: Colors.green,
                              )
                            : const Chip(
                                label: Text('Inactive'),
                                backgroundColor: Colors.grey,
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
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Assignments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _staffUsers.isEmpty
              ? const Center(child: Text('No staff members found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _staffUsers.length,
                  itemBuilder: (context, index) {
                    final staff = _staffUsers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(staff.email),
                        subtitle: const Text('Staff Member'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showStaffAssignments(staff),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateAssignmentDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
