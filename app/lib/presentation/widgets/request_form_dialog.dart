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

  /// Validates and formats room number.
  /// Format: {1-3 capital letters}{1-3 digits} or {1-3 capital letters}{1-3 digits}/{digit}
  /// Examples: A1 → A001, ABC123 → ABC123, AB12/5 → AB012/5, A/2 → A000/2
  /// Returns formatted room or null if invalid
  String? _validateRoomNumber(String input) {
    if (input.trim().isEmpty) return null;

    final cleaned = input.replaceAll(RegExp(r'[^a-zA-Z0-9/]'), '').toUpperCase();
    if (cleaned.isEmpty) return null;

    // Split by /
    final parts = cleaned.split('/');
    if (parts.length > 2) return null;

    final mainPart = parts[0];
    final suffixPart = parts.length > 1 ? parts[1] : null;

    // Validate suffix if present - must be single digit
    if (suffixPart != null) {
      if (suffixPart.length != 1 || !RegExp(r'\d').hasMatch(suffixPart)) {
        return null;
      }
    }

    // Main part must start with letter
    if (mainPart.isEmpty || !RegExp(r'^[A-Z]').hasMatch(mainPart)) {
      return null;
    }

    // Extract letters and digits from main part
    int letterCount = 0;
    int digitCount = 0;
    bool seenDigit = false;
    String letters = '';
    String digits = '';

    for (final char in mainPart.characters) {
      if (RegExp(r'[A-Z]').hasMatch(char)) {
        if (seenDigit) return null; // Letter after digit
        if (letterCount >= 3) return null; // More than 3 letters
        letters += char;
        letterCount++;
      } else if (RegExp(r'\d').hasMatch(char)) {
        if (digitCount >= 3) return null; // More than 3 digits
        digits += char;
        digitCount++;
        seenDigit = true;
      } else {
        return null;
      }
    }

    // Must have at least 1 digit
    if (digitCount == 0) return null;

    // Pad digits to 3 digits with leading zeros
    final paddedDigits = digits.padLeft(3, '0');

    final formattedMain = '$letters$paddedDigits';
    return suffixPart != null ? '$formattedMain/$suffixPart' : formattedMain;
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
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Room is required';
                    }
                    if (_validateRoomNumber(v) == null) {
                      return 'Format: 1-3 letters + 1-3 digits (e.g., A1, ABC123) or + /digit (e.g., AB12/5)';
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
    
    // Validate and format room number
    final rawRoom = _roomController.text.trim();
    final formattedRoom = _validateRoomNumber(rawRoom);
    
    if (formattedRoom == null) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid room format')),
        );
      }
      return;
    }
    
    final success =
        await ref.read(myRequestsProvider('raised').notifier).createRequest(
              mainType: _selectedMainName!,
              subType: _selectedSubName!,
              description: _descController.text.trim(),
              roomNo: formattedRoom,
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
