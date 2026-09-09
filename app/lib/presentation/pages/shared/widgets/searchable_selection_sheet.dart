import 'package:flutter/material.dart';

/// Opens a searchable bottom sheet and returns the selected item.
///
/// Example:
///
/// final room = await showSearchableSelectionSheet<Room>(
///   context: context,
///   title: 'Select Room',
///   items: rooms,
///   labelBuilder: (room) => room.roomNo,
/// );
Future<T?> showSearchableSelectionSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T item) labelBuilder,
  T? selectedItem,
  String searchHint = 'Search...',
  Widget Function(T item)? leadingBuilder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _SearchableSelectionSheet<T>(
        title: title,
        items: items,
        labelBuilder: labelBuilder,
        selectedItem: selectedItem,
        searchHint: searchHint,
        leadingBuilder: leadingBuilder,
      );
    },
  );
}

class _SearchableSelectionSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T item) labelBuilder;
  final T? selectedItem;
  final String searchHint;
  final Widget Function(T item)? leadingBuilder;

  const _SearchableSelectionSheet({
    required this.title,
    required this.items,
    required this.labelBuilder,
    this.selectedItem,
    required this.searchHint,
    this.leadingBuilder,
  });

  @override
  State<_SearchableSelectionSheet<T>> createState() =>
      _SearchableSelectionSheetState<T>();
}

class _SearchableSelectionSheetState<T>
    extends State<_SearchableSelectionSheet<T>> {
  final _searchController = TextEditingController();

  late List<T> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  void _filterItems() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          return widget.labelBuilder(item).toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_filterItems)
      ..dispose();

    super.dispose();
  }

  bool _isSelected(T item) {
    return widget.selectedItem != null && widget.selectedItem == item;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear',
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.clear_rounded),
                        )
                      : null,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),

            Divider(
              height: 1,
              color: colorScheme.outlineVariant,
            ),

            // Results
            Flexible(
              child: _filteredItems.isEmpty
                  ? _EmptyState(
                      searchQuery: _searchController.text,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                      ),
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      separatorBuilder: (_, __) => const SizedBox(
                        height: 2,
                      ),
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final selected = _isSelected(item);

                        return _SelectionItem<T>(
                          item: item,
                          label: widget.labelBuilder(item),
                          selected: selected,
                          leadingBuilder: widget.leadingBuilder,
                          onTap: () {
                            Navigator.pop(context, item);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionItem<T> extends StatelessWidget {
  final T item;
  final String label;
  final bool selected;
  final Widget Function(T item)? leadingBuilder;
  final VoidCallback onTap;

  const _SelectionItem({
    required this.item,
    required this.label,
    required this.selected,
    required this.leadingBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: selected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
            child: Row(
              children: [
                if (leadingBuilder != null) ...[
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: leadingBuilder!(item),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: selected
                      ? Icon(
                          Icons.check_circle_rounded,
                          key: const ValueKey('selected'),
                          color: colorScheme.primary,
                        )
                      : const SizedBox(
                          key: ValueKey('unselected'),
                          width: 24,
                          height: 24,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String searchQuery;

  const _EmptyState({
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 48,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 42,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            searchQuery.isEmpty ? 'No items available' : 'No results found',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Try a different search term',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
