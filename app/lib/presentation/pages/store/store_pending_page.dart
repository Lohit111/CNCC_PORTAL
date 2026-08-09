import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/presentation/providers/store_provider.dart';
import 'store_request_card.dart';

class StorePendingPage extends ConsumerWidget {
  const StorePendingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeProvider('pending'));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        if (data.storeRequests.isEmpty) {
          return _empty(context, 'No pending store requests');
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.read(storeProvider('pending').notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: data.storeRequests.length,
            itemBuilder: (_, i) => StoreRequestCard(
              detail: data.storeRequests[i],
              category: 'pending',
            ),
          ),
        );
      },
    );
  }
}

Widget _empty(BuildContext context, String msg) {
  final cs = Theme.of(context).colorScheme;
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.store_rounded,
            size: 56, color: cs.onSurface.withValues(alpha: 0.2)),
        const SizedBox(height: 14),
        Text(msg,
            style: TextStyle(
                fontSize: 16, color: cs.onSurface.withValues(alpha: 0.5))),
      ],
    ),
  );
}
