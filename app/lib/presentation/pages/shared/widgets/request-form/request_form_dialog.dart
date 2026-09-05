import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/presentation/providers/my_requests_provider.dart';
import 'package:cncc_portal/presentation/providers/rooms_provider.dart';
import 'package:cncc_portal/presentation/providers/types_provider.dart';

/// Shared "New Request" dialog used by all role home pages.
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => RequestFormDialog(
///     onSuccess: () => ref.invalidate(myRequestsProvider('raised')),
///   ),
/// );
/// ```
class RequestFormDialog extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const RequestFormDialog({super.key, required this.onSuccess});

  @override
  ConsumerState<RequestFormDialog> createState() => _RequestFormDialogState();
}

class _RequestFormDialogState extends ConsumerState<RequestFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();

  int? _selectedMainId;
  int? _selectedSubId;
  String? _selectedMainName;
  String? _selectedSubName;
  int? _selectedRoomId;
  String? _selectedRoomNo;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mainTypesAsync = ref.watch(mainTypesProvider);
    final roomsAsync = ref.watch(roomsProvider);

    return AlertDialog(
      title: const Text('New Request'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main type
                mainTypesAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Failed to load types: $e'),
                  data: (mainTypes) => DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Main Type'),
                    value: _selectedMainId,
                    items: mainTypes
                        .map((t) =>
                            DropdownMenuItem(value: t.id, child: Text(t.name)))
                        .toList(),
                    onChanged: (val) {
                      final mt = mainTypes.firstWhere((t) => t.id == val);
                      setState(() {
                        _selectedMainId = val;
                        _selectedMainName = mt.name;
                        _selectedSubId = null;
                        _selectedSubName = null;
                      });
                    },
                    validator: (v) =>
                        v == null ? 'Please select a main type' : null,
                  ),
                ),

                const SizedBox(height: 12),

                // Sub type — only shown once a main type is selected
                if (_selectedMainId != null)
                  Consumer(builder: (_, ref, __) {
                    final subAsync =
                        ref.watch(subTypesProvider(_selectedMainId!));
                    return subAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Failed to load sub types: $e'),
                      data: (subs) => DropdownButtonFormField<int>(
                        decoration:
                            const InputDecoration(labelText: 'Sub Type'),
                        value: _selectedSubId,
                        items: subs
                            .map((t) => DropdownMenuItem(
                                value: t.id, child: Text(t.name)))
                            .toList(),
                        onChanged: (val) {
                          final st = subs.firstWhere((t) => t.id == val);
                          setState(() {
                            _selectedSubId = val;
                            _selectedSubName = st.name;
                          });
                        },
                        validator: (v) =>
                            v == null ? 'Please select a sub type' : null,
                      ),
                    );
                  }),

                const SizedBox(height: 12),

                // Room
                roomsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Failed to load rooms: $e'),
                  data: (rooms) => DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Room'),
                    value: _selectedRoomId,
                    items: rooms
                        .map((r) => DropdownMenuItem(
                            value: r.id, child: Text(r.roomNo)))
                        .toList(),
                    onChanged: (val) {
                      final room = rooms.firstWhere((r) => r.id == val);
                      setState(() {
                        _selectedRoomId = val;
                        _selectedRoomNo = room.roomNo;
                      });
                    },
                    validator: (v) => v == null ? 'Please select a room' : null,
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Description is required'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMainName == null || _selectedSubName == null) return;
    if (_selectedRoomNo == null) return;

    setState(() => _isSubmitting = true);
    final success =
        await ref.read(myRequestsProvider('raised').notifier).createRequest(
              mainType: _selectedMainName!,
              subType: _selectedSubName!,
              description: _descController.text.trim(),
              roomNo: _selectedRoomNo!,
            );
    if (mounted) {
      Navigator.pop(context);
      if (success) widget.onSuccess();
    }
  }
}
