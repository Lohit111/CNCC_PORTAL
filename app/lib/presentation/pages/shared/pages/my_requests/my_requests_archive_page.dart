import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/presentation/providers/my_requests_provider.dart';
import 'package:cncc_portal/presentation/pages/shared/widgets/request-tile/request_card.dart';

class MyRequestsArchivePage extends ConsumerWidget {
  const MyRequestsArchivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myRequestsProvider('archive'));

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        if (data.requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt_rounded,
                    size: 56,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.2)),
                const SizedBox(height: 14),
                Text('No archived requests',
                    style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5))),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.read(myRequestsProvider('archive').notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: data.requests.length,
            itemBuilder: (_, i) => RequestCard(
              detail: data.requests[i],
              onRefresh: () =>
                  ref.read(myRequestsProvider('archive').notifier).refresh(),
            ),
          ),
        );
      },
    );
  }
}
