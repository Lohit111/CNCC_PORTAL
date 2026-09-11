import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/presentation/providers/admin_provider.dart';
import 'package:cncc_portal/presentation/pages/shared/widgets/request-tile/request_card.dart';

class AdminSearchPage extends ConsumerStatefulWidget {
  const AdminSearchPage({super.key});

  @override
  ConsumerState<AdminSearchPage> createState() => _AdminSearchPageState();
}

class _AdminSearchPageState extends ConsumerState<AdminSearchPage> {
  final _controller = TextEditingController();
  String _prefix = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resultsAsync = ref.watch(adminSearchProvider(_prefix));

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: _controller,
            autofocus: false,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Enter request ID prefix…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _prefix.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _prefix = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: cs.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            ),
            onChanged: (v) => setState(() => _prefix = v.trim()),
          ),
        ),

        // Results
        Expanded(
          child: _prefix.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.manage_search_rounded,
                          size: 56,
                          color: cs.onSurface.withValues(alpha: 0.18)),
                      const SizedBox(height: 14),
                      Text(
                        'Enter an ID to search',
                        style: TextStyle(
                          fontSize: 15,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                )
              : resultsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: TextStyle(color: cs.error),
                    ),
                  ),
                  data: (requests) {
                    if (requests.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 56,
                                color: cs.onSurface.withValues(alpha: 0.18)),
                            const SizedBox(height: 14),
                            Text(
                              'No requests found for "$_prefix"',
                              style: TextStyle(
                                fontSize: 15,
                                color: cs.onSurface.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: requests.length,
                      itemBuilder: (_, i) => RequestCard(
                        detail: requests[i],
                        onRefresh: () => ref.invalidate(
                          adminSearchProvider(_prefix),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
