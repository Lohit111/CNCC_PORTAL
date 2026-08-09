import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/presentation/providers/staff_provider.dart';
import 'staff_request_action_card.dart';

class StaffAssignedPage extends ConsumerWidget {
  const StaffAssignedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(staffProvider('assigned'));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        if (data.requests.isEmpty) {
          return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(Icons.assignment_ind_rounded,
                    size: 56, color: cs.onSurface.withValues(alpha: 0.2)),
                const SizedBox(height: 14),
                Text('No requests assigned to you',
                    style: TextStyle(
                        fontSize: 16,
                        color: cs.onSurface.withValues(alpha: 0.5))),
              ]));
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.read(staffProvider('assigned').notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: data.requests.length,
            itemBuilder: (_, i) => StaffRequestActionCard(
                detail: data.requests[i], category: 'assigned'),
          ),
        );
      },
    );
  }
}
