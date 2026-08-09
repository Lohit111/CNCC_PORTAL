import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/presentation/providers/store_provider.dart';
import 'store_request_card.dart';

class StoreArchivePage extends ConsumerWidget {
  const StoreArchivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeProvider('archive'));
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
                Icon(Icons.archive_rounded,
                    size: 56, color: cs.onSurface.withValues(alpha: 0.2)),
                const SizedBox(height: 14),
                Text('No archived store requests',
                    style: TextStyle(
                        fontSize: 16,
                        color: cs.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.read(storeProvider('archive').notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: data.storeRequests.length,
            itemBuilder: (_, i) => StoreRequestCard(
              detail: data.storeRequests[i],
              category: 'archive',
            ),
          ),
        );
      },
    );
  }
}
