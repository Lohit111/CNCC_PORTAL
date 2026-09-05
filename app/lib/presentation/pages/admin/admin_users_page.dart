import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/domain/entities/user_entity.dart';
import 'package:cncc_portal/presentation/providers/users_provider.dart';

class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usersProvider);

    return Scaffold(
      body: Column(
        children: [
          if (state.isLoading) const LinearProgressIndicator(),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Error: ${state.error}',
                  style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.read(usersProvider.notifier).fetch(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: state.users.length,
                itemBuilder: (_, i) => _UserTile(user: state.users[i]),
              ),
            ),
          ),
          // Pagination
          if (state.pages > 1)
            _PaginationRow(
              page: state.page,
              pages: state.pages,
              onPrev: () => ref.read(usersProvider.notifier).prevPage(),
              onNext: () => ref.read(usersProvider.notifier).nextPage(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add User',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    String selectedRole = 'USER';
    final roles = ['USER', 'ADMIN', 'STAFF', 'STORE'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => selectedRole = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (emailCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await ref
                    .read(usersProvider.notifier)
                    .createUser(emailCtrl.text.trim(), selectedRole);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  final User user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final displayName = user.name ?? user.email;
    final roleColor = _roleColor(user.role);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: roleColor.withValues(alpha: 0.15),
                child: Text(
                  displayName.characters.first.toUpperCase(),
                  style:
                      TextStyle(fontWeight: FontWeight.w700, color: roleColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    if (user.name != null)
                      Text(user.email,
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.5))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        user.role,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: roleColor),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    size: 20, color: cs.onSurface.withValues(alpha: 0.4)),
                onSelected: (action) => _handleAction(context, ref, action),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'role',
                      child: Row(children: [
                        Icon(Icons.manage_accounts_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Change Role'),
                      ])),
                  const PopupMenuItem(
                      value: 'deactivate',
                      child: Row(children: [
                        Icon(Icons.person_off_rounded,
                            size: 18, color: Color(0xFFF38BA8)),
                        SizedBox(width: 8),
                        Text('Deactivate',
                            style: TextStyle(color: Color(0xFFF38BA8))),
                      ])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    if (action == 'role') {
      _showRoleDialog(context, ref);
    } else if (action == 'deactivate') {
      _confirmDeactivate(context, ref);
    }
  }

  void _showRoleDialog(BuildContext context, WidgetRef ref) {
    String selected = user.role;
    final roles = ['USER', 'ADMIN', 'STAFF', 'STORE'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Change Role — ${user.name ?? user.email}'),
          content: DropdownButtonFormField<String>(
            initialValue: selected,
            decoration: const InputDecoration(labelText: 'Role'),
            items: roles
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() => selected = v!),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref
                    .read(usersProvider.notifier)
                    .updateRole(user.id, selected);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text(
            'Deactivate ${user.name ?? user.email}? They will no longer be able to log in.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF38BA8)),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(usersProvider.notifier).deactivateUser(user.id);
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return const Color(0xFFF38BA8);
      case 'STAFF':
        return const Color(0xFFCBA6F7);
      case 'STORE':
        return const Color(0xFF94E2D5);
      default:
        return const Color(0xFF89B4FA);
    }
  }
}

class _PaginationRow extends StatelessWidget {
  final int page;
  final int pages;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _PaginationRow({
    required this.page,
    required this.pages,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: page > 1 ? onPrev : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text('$page / $pages',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          IconButton(
            onPressed: page < pages ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
