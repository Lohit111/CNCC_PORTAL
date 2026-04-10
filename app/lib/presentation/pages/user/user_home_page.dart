import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/type_entity.dart';
import 'package:cncc_portal/presentation/pages/user/active_requests_page.dart';
import 'package:cncc_portal/presentation/pages/user/replied_requests_user_page.dart';
import 'package:cncc_portal/presentation/pages/user/completed_requests_user_page.dart';

class UserHomePage extends ConsumerStatefulWidget {
  const UserHomePage({super.key});

  @override
  ConsumerState<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends ConsumerState<UserHomePage> {
  final _networkClient = NetworkClient();
  int _selectedIndex = 0;

  void _showCreateRequestDialog() async {
    final mainTypes = await _loadMainTypes();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => _CreateRequestDialog(mainTypes: mainTypes),
    );
  }

  Future<List<MainType>> _loadMainTypes() async {
    try {
      final response = await _networkClient.get('/types/main');
      return (response.data as List)
          .map((json) => MainType.fromJson(json))
          .toList();
    } catch (e) {
      return [];
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
            icon: Icon(Icons.pending_actions),
            label: 'Active',
          ),
          NavigationDestination(
            icon: Icon(Icons.reply),
            label: 'Needs Response',
          ),
          NavigationDestination(
            icon: Icon(Icons.archive),
            label: 'Completed',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRequestDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const ActiveRequestsPage();
      case 1:
        return const RepliedRequestsUserPage();
      case 2:
        return const CompletedRequestsUserPage();
      default:
        return const ActiveRequestsPage();
    }
  }
}

class _CreateRequestDialog extends StatefulWidget {
  final List<MainType> mainTypes;

  const _CreateRequestDialog({required this.mainTypes});

  @override
  State<_CreateRequestDialog> createState() => _CreateRequestDialogState();
}

class _CreateRequestDialogState extends State<_CreateRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _networkClient = NetworkClient();

  MainType? _selectedMainType;
  SubType? _selectedSubType;
  List<SubType> _subTypes = [];
  bool _isLoading = false;

  Future<void> _loadSubTypes(int mainTypeId) async {
    try {
      final response = await _networkClient.get('/types/main/$mainTypeId/sub');
      setState(() {
        _subTypes = (response.data as List)
            .map((json) => SubType.fromJson(json))
            .toList();
        _selectedSubType = null;
      });
    } catch (e) {
      setState(() => _subTypes = []);
    }
  }

  Future<void> _createRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _networkClient.post('/requests/', data: {
        'main_type_id': _selectedMainType!.id,
        'sub_type_id': _selectedSubType!.id,
        'description': _descriptionController.text,
      });

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request created successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Request'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<MainType>(
                initialValue: _selectedMainType,
                decoration: const InputDecoration(labelText: 'Main Type'),
                items: widget.mainTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMainType = value;
                    if (value != null) {
                      _loadSubTypes(value.id);
                    }
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a main type' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SubType>(
                initialValue: _selectedSubType,
                decoration: const InputDecoration(labelText: 'Sub Type'),
                items: _subTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedSubType = value);
                },
                validator: (value) =>
                    value == null ? 'Please select a sub type' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createRequest,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
