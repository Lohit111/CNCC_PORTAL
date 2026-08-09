import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/presentation/providers/my_requests_provider.dart';
import 'package:cncc_portal/presentation/pages/shared/request_card.dart';

class UserRaisedPage extends ConsumerWidget {
  const UserRaisedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myRequestsProvider('raised'));

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        if (data.requests.isEmpty) {
          return _EmptyState(
            icon: Icons.inbox_rounded,
            message: 'No raised requests',
            sub: 'Tap the + button to raise a new request',
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.read(myRequestsProvider('raised').notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: data.requests.length,
            itemBuilder: (_, i) => RequestCard(
              detail: data.requests[i],
              onRefresh: () =>
                  ref.read(myRequestsProvider('raised').notifier).refresh(),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? sub;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 14),
          Text(message,
              style: TextStyle(
                  fontSize: 16, color: cs.onSurface.withValues(alpha: 0.5))),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(sub!,
                style: TextStyle(
                    fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3))),
          ],
        ],
      ),
    );
  }
}
