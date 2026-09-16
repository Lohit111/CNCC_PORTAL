import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/presentation/providers/my_requests_provider.dart';
import 'package:cncc_portal/presentation/providers/departments_provider.dart';
import 'package:cncc_portal/presentation/providers/types_provider.dart';
import 'package:cncc_portal/presentation/widgets/searchable_selection_sheet.dart';

/// Shared "New Request" dialog used by all role home pages.
class RequestFormDialog extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const RequestFormDialog({super.key, required this.onSuccess});

  @override
  ConsumerState<RequestFormDialog> createState() => _RequestFormDialogState();
}

class _RequestFormDialogState extends ConsumerState<RequestFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _roomController = TextEditingController();

  int? _selectedMainId;
  int? _selectedSubId;
  String? _selectedMainName;
  String? _selectedSubName;
  int? _selectedDeptId;
  String? _selectedDeptName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mainTypesAsync = ref.watch(mainTypesProvider);
    final deptsAsync = ref.watch(departmentsProvider);

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
                  data: (mainTypes) => _SelectionField(
                    label: 'Main Type',
                    value: _selectedMainName,
                    hint: 'Select a type',
                    onTap: () async {
                      final selected = await showSearchableSelectionSheet(
                        context: context,
                        title: 'Select Main Type',
                        searchHint: 'Search types...',
                        items: mainTypes,
                        selectedItem: _selectedMainId == null
                            ? null
                            : mainTypes.firstWhere(
                                (t) => t.id == _selectedMainId,
                              ),
                        labelBuilder: (type) => type.name,
                      );

                      if (selected == null || !mounted) return;

                      setState(() {
                        _selectedMainId = selected.id;
                        _selectedMainName = selected.name;
                        _selectedSubId = null;
                        _selectedSubName = null;
                      });
                    },
                    validator: () => _selectedMainId == null
                        ? 'Please select a main type'
                        : null,
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
                      data: (subs) => _SelectionField(
                        label: 'Sub Type',
                        value: _selectedSubName,
                        hint: 'Select a sub type',
                        onTap: () async {
                          final selected = await showSearchableSelectionSheet(
                            context: context,
                            title: 'Select Sub Type',
                            searchHint: 'Search sub types...',
                            items: subs,
                            selectedItem: _selectedSubId == null
                                ? null
                                : subs.firstWhere(
                                    (t) => t.id == _selectedSubId,
                                  ),
                            labelBuilder: (type) => type.name,
                          );

                          if (selected == null || !mounted) return;

                          setState(() {
                            _selectedSubId = selected.id;
                            _selectedSubName = selected.name;
                          });
                        },
                        validator: () => _selectedSubId == null
                            ? 'Please select a sub type'
                            : null,
                      ),
                    );
                  }),

                const SizedBox(height: 12),

                // Room — manual text input
                TextFormField(
                  controller: _roomController,
                  decoration: const InputDecoration(
                    labelText: 'Room',
                    hintText: 'e.g., A-103',
                    helperText: 'Format: Letter-3 digits (e.g., A-103)',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Room is required';
                    }
                    final trimmed = v.trim().toUpperCase();
                    // Match pattern: single letter, hyphen, 3 digits
                    if (!RegExp(r'^[A-Z]-\d{3}$').hasMatch(trimmed)) {
                      return 'Format must be: Letter-3 digits (e.g., A-103)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Department
                deptsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Failed to load departments: $e'),
                  data: (depts) => _SelectionField(
                    label: 'Department',
                    value: _selectedDeptName,
                    hint: 'Select a department',
                    onTap: () async {
                      final selected = await showSearchableSelectionSheet(
                        context: context,
                        title: 'Select Department',
                        searchHint: 'Search departments...',
                        items: depts,
                        selectedItem: _selectedDeptId == null
                            ? null
                            : depts.firstWhere(
                                (d) => d.id == _selectedDeptId,
                              ),
                        labelBuilder: (dept) => dept.department,
                      );

                      if (selected == null || !mounted) return;

                      setState(() {
                        _selectedDeptId = selected.id;
                        _selectedDeptName = selected.department;
                      });
                    },
                    validator: () => _selectedDeptId == null
                        ? 'Please select a department'
                        : null,
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
    if (_selectedDeptName == null) return;

    setState(() => _isSubmitting = true);
    final roomNo = _roomController.text.trim().toUpperCase();
    final success =
        await ref.read(myRequestsProvider('raised').notifier).createRequest(
              mainType: _selectedMainName!,
              subType: _selectedSubName!,
              description: _descController.text.trim(),
              roomNo: roomNo,
              department: _selectedDeptName!,
            );
    if (mounted) {
      Navigator.pop(context);
      if (success) widget.onSuccess();
    }
  }
}

class _SelectionField extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;
  final String? Function()? validator;

  const _SelectionField({
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => validator?.call(),
      builder: (field) {
        return InkWell(
          onTap: () {
            field.reset();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              errorText: field.errorText,
              suffixIcon: const Icon(
                Icons.keyboard_arrow_down_rounded,
              ),
            ),
            child: Text(
              value ?? hint,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        );
      },
    );
  }
}
