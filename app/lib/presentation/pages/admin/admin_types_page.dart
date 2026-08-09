import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/presentation/providers/types_provider.dart';

class AdminTypesPage extends ConsumerWidget {
  const AdminTypesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainTypesAsync = ref.watch(mainTypesProvider);

    return Scaffold(
      body: mainTypesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (mainTypes) => RefreshIndicator(
          onRefresh: () async => ref.read(mainTypesProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: mainTypes.length,
            itemBuilder: (_, i) {
              final mt = mainTypes[i];
              return _MainTypeTile(mainId: mt.id, mainName: mt.name);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMainDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Type',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showAddMainDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Main Type'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await ref
                  .read(mainTypesProvider.notifier)
                  .create(ctrl.text.trim());
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _MainTypeTile extends ConsumerWidget {
  final int mainId;
  final String mainName;

  const _MainTypeTile({required this.mainId, required this.mainName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final subAsync = ref.watch(subTypesProvider(mainId));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.category_rounded, size: 18, color: cs.primary),
        ),
        title: Text(mainName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 18),
              onPressed: () => _editMain(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded,
                  size: 18, color: Color(0xFFF38BA8)),
              onPressed: () => _deleteMain(context, ref),
            ),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
        children: [
          // Sub types
          subAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Error: $e'),
            ),
            data: (subTypes) => Column(
              children: [
                ...subTypes.map((st) => ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(32, 0, 8, 0),
                      title:
                          Text(st.name, style: const TextStyle(fontSize: 13)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            onPressed: () =>
                                _editSub(context, ref, st.id, st.name),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_rounded,
                                size: 16, color: Color(0xFFF38BA8)),
                            onPressed: () => _deleteSub(context, ref, st.id),
                          ),
                        ],
                      ),
                    )),
                // Add sub type button
                TextButton.icon(
                  onPressed: () => _addSub(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Sub Type'),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editMain(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: mainName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Main Type'),
        content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Name'),
            autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await ref
                  .read(mainTypesProvider.notifier)
                  .updateType(mainId, ctrl.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteMain(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Main Type'),
        content: Text(
            'Delete "$mainName"? This will also delete all sub types under it.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF38BA8)),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(mainTypesProvider.notifier).delete(mainId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addSub(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Sub Type to $mainName'),
        content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Name'),
            autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await ref
                  .read(subTypesProvider(mainId).notifier)
                  .create(ctrl.text.trim());
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editSub(
      BuildContext context, WidgetRef ref, int subId, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Sub Type'),
        content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Name'),
            autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await ref
                  .read(subTypesProvider(mainId).notifier)
                  .updateSubType(subId, ctrl.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteSub(BuildContext context, WidgetRef ref, int subId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sub Type'),
        content: const Text('Delete this sub type?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF38BA8)),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(subTypesProvider(mainId).notifier).delete(subId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
