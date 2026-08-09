import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/presentation/providers/admin_provider.dart';
import 'admin_request_action_card.dart';

class AdminRaisedPage extends ConsumerWidget {
  const AdminRaisedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(adminProvider('raised'));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        if (data.requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded,
                    size: 56, color: cs.onSurface.withValues(alpha: 0.2)),
                const SizedBox(height: 14),
                Text('No raised requests',
                    style: TextStyle(
                        fontSize: 16,
                        color: cs.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.read(adminProvider('raised').notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: data.requests.length,
            itemBuilder: (_, i) => AdminRequestActionCard(
                detail: data.requests[i], category: 'raised'),
          ),
        );
      },
    );
  }
}
