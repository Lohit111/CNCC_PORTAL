import 'package:flutter/material.dart';
import 'package:ticket_management_app/core/network/network_client.dart';
import 'package:ticket_management_app/domain/entities/type_entity.dart';

class ManageTypesPage extends StatefulWidget {
  const ManageTypesPage({super.key});

  @override
  State<ManageTypesPage> createState() => _ManageTypesPageState();
}

class _ManageTypesPageState extends State<ManageTypesPage> {
  final _networkClient = NetworkClient();
  List<MainType> _mainTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMainTypes();
  }

  Future<void> _loadMainTypes() async {
    setState(() => _isLoading = true);
    try {
      final response = await _networkClient.get('/types/main');
      setState(() {
        _mainTypes = (response.data as List)
            .map((json) => MainType.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateMainTypeDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Main Type'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _networkClient.post('/types/main', data: {
                  'name': nameController.text,
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Main type created')),
                  );
                  _loadMainTypes();
                }
              } catch (e) {
                if (mounted) {
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
    );
  }

  void _showSubTypesDialog(MainType mainType) async {
    try {
      final response = await _networkClient.get('/types/main/${mainType.id}/sub');
      final subTypes = (response.data as List)
          .map((json) => SubType.fromJson(json))
          .toList();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => _SubTypesDialog(
          mainType: mainType,
          subTypes: subTypes,
          onRefresh: _loadMainTypes,
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
        title: const Text('Manage Types'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMainTypes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mainTypes.isEmpty
              ? const Center(child: Text('No main types found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _mainTypes.length,
                  itemBuilder: (context, index) {
                    final mainType = _mainTypes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(mainType.name),
                        subtitle: Text('Created: ${_formatDate(mainType.createdAt)}'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showSubTypesDialog(mainType),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMainTypeDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SubTypesDialog extends StatefulWidget {
  final MainType mainType;
  final List<SubType> subTypes;
  final VoidCallback onRefresh;

  const _SubTypesDialog({
    required this.mainType,
    required this.subTypes,
    required this.onRefresh,
  });

  @override
  State<_SubTypesDialog> createState() => _SubTypesDialogState();
}

class _SubTypesDialogState extends State<_SubTypesDialog> {
  final _networkClient = NetworkClient();
  late List<SubType> _subTypes;

  @override
  void initState() {
    super.initState();
    _subTypes = widget.subTypes;
  }

  Future<void> _loadSubTypes() async {
    try {
      final response = await _networkClient.get('/types/main/${widget.mainType.id}/sub');
      setState(() {
        _subTypes = (response.data as List)
            .map((json) => SubType.fromJson(json))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showCreateSubTypeDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Sub Type'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _networkClient.post('/types/sub', data: {
                  'name': nameController.text,
                  'main_type_id': widget.mainType.id,
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sub type created')),
                  );
                  _loadSubTypes();
                  widget.onRefresh();
                }
              } catch (e) {
                if (mounted) {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sub Types: ${widget.mainType.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: _subTypes.isEmpty
            ? const Center(child: Text('No sub types'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _subTypes.length,
                itemBuilder: (context, index) {
                  final subType = _subTypes[index];
                  return ListTile(
                    title: Text(subType.name),
                    dense: true,
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: _showCreateSubTypeDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Sub Type'),
        ),
      ],
    );
  }
}
