import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/presentation/providers/store_provider.dart';
import 'store_request_card.dart';

class StoreApprovedPage extends ConsumerWidget {
  const StoreApprovedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeProvider('approved'));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        if (data.storeRequests.isEmpty) {
          final cs = Theme.of(context).colorScheme;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_rounded,
                    size: 56, color: cs.onSurface.withValues(alpha: 0.2)),
                const SizedBox(height: 14),
                Text('No approved store requests',
                    style: TextStyle(
                        fontSize: 16,
                        color: cs.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.read(storeProvider('approved').notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: data.storeRequests.length,
            itemBuilder: (_, i) => StoreRequestCard(
              detail: data.storeRequests[i],
              category: 'approved',
            ),
          ),
        );
      },
    );
  }
}
