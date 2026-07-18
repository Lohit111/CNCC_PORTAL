import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/type_entity.dart';

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
        title: const Text('Create Category'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g. Infrastructure',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              try {
                await _networkClient.post('/types/main', data: {'name': name});
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category created')),
                  );
                  _loadMainTypes();
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
    );
  }

  void _showSubTypesDialog(MainType mainType) async {
    try {
      final response =
          await _networkClient.get('/types/main/${mainType.id}/sub');
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Types'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadMainTypes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mainTypes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_rounded,
                          size: 56, color: cs.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 14),
                      Text('No categories yet',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.4))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: _mainTypes.length,
                  itemBuilder: (context, index) {
                    final mainType = _mainTypes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _showSubTypesDialog(mainType),
                          child: Container(
                            decoration: BoxDecoration(
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
                                  color: cs.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.category_rounded,
                                    color: cs.primary, size: 18),
                              ),
                              title: Text(mainType.name,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: cs.onSurface)),
                              subtitle: Text(
                                'Created ${_formatDate(mainType.createdAt)}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withValues(alpha: 0.4)),
                              ),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: cs.onSurface.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMainTypeDialog,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

// ── Sub-types dialog ──────────────────────────────────────────────────────────

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
      final response =
          await _networkClient.get('/types/main/${widget.mainType.id}/sub');
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
        title: Text('Add Sub-type to ${widget.mainType.name}'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Sub-type Name',
            hintText: 'e.g. Network Issue',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              try {
                await _networkClient.post('/types/sub', data: {
                  'name': name,
                  'main_type_id': widget.mainType.id,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sub-type created')),
                  );
                  _loadSubTypes();
                  widget.onRefresh();
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.category_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text(widget.mainType.name),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _subTypes.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No sub-types yet',
                    style:
                        TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _subTypes.length,
                itemBuilder: (context, index) {
                  final subType = _subTypes[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.subdirectory_arrow_right_rounded,
                            size: 14,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(width: 8),
                        Text(subType.name,
                            style:
                                TextStyle(fontSize: 13, color: cs.onSurface)),
                      ],
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
        ElevatedButton.icon(
          onPressed: _showCreateSubTypeDialog,
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add Sub-type'),
        ),
      ],
    );
  }
}
