import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cncc_portal/presentation/providers/my_requests_provider.dart';
import 'package:cncc_portal/presentation/providers/departments_provider.dart';
import 'package:cncc_portal/presentation/providers/types_provider.dart';
import 'package:cncc_portal/presentation/providers/request_file_provider.dart';
import 'package:cncc_portal/presentation/widgets/searchable_selection_sheet.dart';
import 'package:cncc_portal/services/file_service.dart';
import 'package:cncc_portal/presentation/widgets/multi_select_subtypes.dart';

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
  String? _selectedMainName;
  List<SubTypeSelection> _selectedSubTypes = [];
  int? _selectedDeptId;
  String? _selectedDeptName;
  bool _isSubmitting = false;

  // Files to be uploaded after request creation
  final List<PlatformFile> _selectedFiles = [];

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

    final cleaned =
        input.replaceAll(RegExp(r'[^a-zA-Z0-9/]'), '').toUpperCase();
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

  Future<void> _pickAndAddFiles() async {
    final files = await FileService.showFilePickerModal(context);
    if (files.isEmpty) return;

    if (!mounted) return;

    setState(() {
      _selectedFiles.addAll(files);
    });
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
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
                        _selectedSubTypes = [];
                      });
                    },
                    validator: () => _selectedMainId == null
                        ? 'Please select a main type'
                        : null,
                  ),
                ),

                // Sub type — multi-select only shown once a main type is selected
                if (_selectedMainId != null) const SizedBox(height: 12),
                if (_selectedMainId != null)
                  Consumer(builder: (_, ref, __) {
                    final subAsync =
                        ref.watch(subTypesProvider(_selectedMainId!));
                    return subAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Failed to load sub types: $e'),
                      data: (subs) => MultiSelectSubTypesWidget(
                        availableSubTypes: subs
                            .map((s) => SubTypeSelection(
                                  id: s.id,
                                  name: s.name,
                                ))
                            .toList(),
                        onSelectionChanged: (selected) {
                          setState(() {
                            _selectedSubTypes = selected;
                          });
                        },
                      ),
                    );
                  }),
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

                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Description is required'
                      : null,
                ),

                const SizedBox(height: 16),

                // Files section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Files (${_selectedFiles.length})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickAndAddFiles,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Selected files list
                if (_selectedFiles.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedFiles.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (_, index) {
                        final file = _selectedFiles[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                _getFileIcon(file.name),
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      file.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${(file.size / 1024).toStringAsFixed(1)} KB',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () => _removeFile(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
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

  IconData _getFileIcon(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return Icons.image_rounded;
    }
    if (['pdf'].contains(ext)) return Icons.picture_as_pdf_rounded;
    if (['doc', 'docx', 'txt'].contains(ext)) return Icons.description_rounded;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMainName == null) return;
    if (_selectedSubTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one sub type')),
      );
      return;
    }
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

    // Construct combined sub_type: "type1-num1,type2-num2,..."
    final subTypeString = _selectedSubTypes
        .map((item) => '${item.name}-${item.quantity}')
        .join(',');

    // Phase 1: Create the request
    final requestId =
        await ref.read(myRequestsProvider('raised').notifier).createRequest(
              mainType: _selectedMainName!,
              subType: subTypeString,
              description: _descController.text.trim(),
              roomNo: formattedRoom,
              department: _selectedDeptName!,
            );

    if (requestId == null || !mounted) {
      setState(() => _isSubmitting = false);
      return;
    }

    // If there are files to upload, show Phase 2 (upload dialog)
    if (_selectedFiles.isNotEmpty) {
      if (mounted) {
        Navigator.pop(context);
        // Show upload progress dialog
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => _UploadProgressDialog(
              requestId: requestId,
              files: _selectedFiles,
            ),
          );
        }
        if (mounted) widget.onSuccess();
      }
    } else {
      // No files, just close and callback
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
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

/// Two-phase upload dialog shown after request creation.
/// Displays progress as files are uploaded sequentially.
class _UploadProgressDialog extends ConsumerStatefulWidget {
  final String requestId;
  final List<PlatformFile> files;

  const _UploadProgressDialog({
    required this.requestId,
    required this.files,
  });

  @override
  ConsumerState<_UploadProgressDialog> createState() =>
      _UploadProgressDialogState();
}

class _UploadProgressDialogState extends ConsumerState<_UploadProgressDialog> {
  int _uploadedCount = 0;
  String? _currentFileName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _uploadFilesSequentially();
  }

  Future<void> _uploadFilesSequentially() async {
    try {
      for (int i = 0; i < widget.files.length; i++) {
        final file = widget.files[i];

        if (!mounted) return;

        setState(() {
          _currentFileName = file.name;
        });

        // Upload file
        await ref
            .read(requestFileProvider(widget.requestId).notifier)
            .upload([file]);

        if (!mounted) return;

        setState(() {
          _uploadedCount = i + 1;
        });
      }

      // All files uploaded successfully
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_errorMessage != null) {
      return AlertDialog(
        title: const Text('Upload Error'),
        content: Text(_errorMessage!),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }

    final progress = _uploadedCount / widget.files.length;

    return AlertDialog(
      title: const Text('Uploading Files'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 16),
            Text(
              'Uploading: $_currentFileName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              '$_uploadedCount / ${widget.files.length} files',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
