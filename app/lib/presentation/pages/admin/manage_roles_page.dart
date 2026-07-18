import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/role_entity.dart';

class ManageRolesPage extends StatefulWidget {
  const ManageRolesPage({super.key});

  @override
  State<ManageRolesPage> createState() => _ManageRolesPageState();
}

class _ManageRolesPageState extends State<ManageRolesPage> {
  final _networkClient = NetworkClient();
  List<Role> _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() => _isLoading = true);
    try {
      final response = await _networkClient.get('/roles/');
      final data = response.data;
      setState(() {
        _roles =
            (data['items'] as List).map((json) => Role.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showCreateRoleDialog() {
    final emailController = TextEditingController();
    String selectedRole = 'USER';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'user@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                dropdownColor: const Color(0xFF313244),
                items: const [
                  DropdownMenuItem(value: 'USER', child: Text('USER')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                  DropdownMenuItem(value: 'STAFF', child: Text('STAFF')),
                  DropdownMenuItem(value: 'STORE', child: Text('STORE')),
                ],
                onChanged: (value) =>
                    setDialogState(() => selectedRole = value!),
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
                final email = emailController.text.trim();
                if (email.isEmpty) return;
                try {
                  await _networkClient.post('/roles/', data: {
                    'email': email,
                    'role': selectedRole,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Role created')),
                    );
                    _loadRoles();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateRoleDialog(Role role) {
    String selectedRole = role.role;
    bool isUpdating = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role.email,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                dropdownColor: const Color(0xFF313244),
                items: const [
                  DropdownMenuItem(value: 'USER', child: Text('USER')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                  DropdownMenuItem(value: 'STAFF', child: Text('STAFF')),
                  DropdownMenuItem(value: 'STORE', child: Text('STORE')),
                ],
                onChanged: isUpdating
                    ? null
                    : (value) => setDialogState(() {
                          selectedRole = value!;
                          errorMessage = null;
                        }),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF38BA8).withValues(alpha: 0.1),
                    border: Border.all(
                        color: const Color(0xFFF38BA8).withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFF38BA8), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                              color: Color(0xFFF38BA8), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isUpdating ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUpdating
                  ? null
                  : () async {
                      setDialogState(() => isUpdating = true);
                      try {
                        await _networkClient.put('/roles/${role.email}',
                            data: {'role': selectedRole});
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Role updated')),
                          );
                          _loadRoles();
                        }
                      } catch (e) {
                        String message = 'Failed to update role.';
                        if (e is DioException && e.response?.data != null) {
                          final detail = e.response!.data['detail'];
                          if (detail != null) message = detail.toString();
                        }
                        setDialogState(() {
                          isUpdating = false;
                          errorMessage = message;
                        });
                      }
                    },
              child: isUpdating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Roles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRoles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _roles.isEmpty
              ? Center(
                  child: Text('No roles found',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.4))))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: _roles.length,
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    final roleColor = _roleColor(role.role);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: cs.onSurface.withValues(alpha: 0.06)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.person_rounded,
                                color: roleColor, size: 18),
                          ),
                          title: Text(role.email,
                              style:
                                  TextStyle(fontSize: 14, color: cs.onSurface)),
                          subtitle: Text(
                            _formatDate(role.createdAt),
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.4)),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  role.role,
                                  style: TextStyle(
                                    color: roleColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                color: const Color(0xFF313244),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_rounded, size: 16),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showUpdateRoleDialog(role);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRoleDialog,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return const Color(0xFFF38BA8);
      case 'STAFF':
        return const Color(0xFF89B4FA);
      case 'STORE':
        return const Color(0xFFA6E3A1);
      case 'USER':
        return const Color(0xFFFAB387);
      default:
        return const Color(0xFF6C7086);
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
