import 'package:flutter/material.dart';

class SubTypeSelection {
  final int id;
  final String name;
  String? quantity;
  bool _isChecked = false; // Track checkbox state separately from quantity value

  SubTypeSelection({
    required this.id,
    required this.name,
    this.quantity,
  });

  bool get isSelected => _isChecked;

  @override
  String toString() => '$name-$quantity';
}

class MultiSelectSubTypesWidget extends StatefulWidget {
  final List<SubTypeSelection> availableSubTypes;
  final ValueChanged<List<SubTypeSelection>> onSelectionChanged;

  const MultiSelectSubTypesWidget({
    super.key,
    required this.availableSubTypes,
    required this.onSelectionChanged,
  });

  @override
  State<MultiSelectSubTypesWidget> createState() =>
      _MultiSelectSubTypesWidgetState();
}

class _MultiSelectSubTypesWidgetState extends State<MultiSelectSubTypesWidget> {
  late Map<int, TextEditingController> _quantityControllers;
  late Map<int, FocusNode> _focusNodes;
  late List<SubTypeSelection> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.availableSubTypes);
    _quantityControllers = {
      for (var item in _selectedItems) item.id: TextEditingController(),
    };
    _focusNodes = {
      for (var item in _selectedItems) item.id: FocusNode(),
    };
    _setupFocusListeners();
  }

  @override
  void dispose() {
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _setupFocusListeners() {
    for (var item in _selectedItems) {
      _focusNodes[item.id]?.removeListener(() {});
      _focusNodes[item.id]?.addListener(() {
        if (!_focusNodes[item.id]!.hasFocus) {
          // Focus lost - check if quantity is empty
          final controller = _quantityControllers[item.id];
          if (controller != null && controller.text.isEmpty) {
            // Uncheck the item if quantity is empty
            _toggleSelection(item.id, false);
          }
        }
      });
    }
  }

  void _toggleSelection(int id, bool isSelected) {
    setState(() {
      final index = _selectedItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _selectedItems[index]._isChecked = isSelected;
        if (isSelected) {
          _selectedItems[index].quantity = '1'; // Default to 1
          _quantityControllers[id]?.text = '1';
        } else {
          _selectedItems[index].quantity = null;
          _quantityControllers[id]?.clear();
        }
      }
    });
    _notifyParent();
  }

  void _updateQuantity(int id, String value) {
    setState(() {
      final index = _selectedItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _selectedItems[index].quantity = value;
      }
    });
    _notifyParent();
  }

  void _notifyParent() {
    final selected = _selectedItems
        .where((item) => item.isSelected && item.quantity != null && item.quantity!.isNotEmpty)
        .toList();
    widget.onSelectionChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sub Types',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedItems.length,
            itemBuilder: (_, index) {
              final item = _selectedItems[index];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: item.isSelected,
                          onChanged: (value) =>
                              _toggleSelection(item.id, value ?? false),
                        ),
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        if (item.isSelected)
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _quantityControllers[item.id],
                              focusNode: _focusNodes[item.id],
                              decoration: InputDecoration(
                                hintText: 'Qty',
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withValues(alpha: 0.4),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color:
                                        cs.outline.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) =>
                                  _updateQuantity(item.id, value),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (index < _selectedItems.length - 1)
                    Divider(
                      height: 1,
                      indent: 12,
                      endIndent: 12,
                      color: cs.outline.withValues(alpha: 0.2),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
