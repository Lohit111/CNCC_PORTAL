import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/type_entity.dart';

/// Reusable dialog for creating a new request.
/// Used by USER, STAFF, and ADMIN home pages.
class CreateRequestDialog extends StatefulWidget {
  final List<MainType> mainTypes;

  const CreateRequestDialog({super.key, required this.mainTypes});

  @override
  State<CreateRequestDialog> createState() => _CreateRequestDialogState();
}

class _CreateRequestDialogState extends State<CreateRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _roomNoController = TextEditingController();
  final _phoneNoController = TextEditingController();
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
        'room_no': _roomNoController.text.trim(),
        'phone_no': _phoneNoController.text.trim(),
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
      title: const Text('New Request'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<MainType>(
                decoration: const InputDecoration(labelText: 'Category'),
                dropdownColor: const Color.fromARGB(255, 234, 249, 248),
                items: widget.mainTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMainType = value;
                    if (value != null) _loadSubTypes(value.id);
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<SubType>(
                decoration: const InputDecoration(labelText: 'Sub-category'),
                dropdownColor: const Color.fromARGB(255, 234, 249, 248),
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
                    value == null ? 'Please select a sub-category' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your request in detail...',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _roomNoController,
                decoration: const InputDecoration(
                  labelText: 'Room No',
                  hintText: 'e.g. A-101',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a room number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneNoController,
                decoration: const InputDecoration(
                  labelText: 'Phone No',
                  hintText: '10-digit phone number',
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a phone number';
                  }
                  if (value.trim().length != 10 ||
                      !RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                    return 'Phone number must be exactly 10 digits';
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
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _roomNoController.dispose();
    _phoneNoController.dispose();
    super.dispose();
  }
}
