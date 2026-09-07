import 'package:cncc_portal/presentation/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/domain/entities/store_request_entity.dart';
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
              child: Text(
                'Error: ${state.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(usersProvider.notifier).fetch(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: state.users.length,
                itemBuilder: (_, i) => _UserTile(
                  user: state.users[i],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text(
          'Add User',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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

// ---------------------------------------------------------------------------
// User tile
// ---------------------------------------------------------------------------

class _UserTile extends ConsumerWidget {
  final User user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final displayName = user.name ?? user.email;
    final roleColor = _roleColor(user.role);
    final isInactive = !user.isActive;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: isInactive ? 0.55 : 1.0,
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
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: roleColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (user.name != null)
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              user.role,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: roleColor,
                              ),
                            ),
                          ),
                          if (isInactive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.onSurface.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'INACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showUserActions(context, ref),
                  icon: const Icon(Icons.more_horiz_rounded),
                  tooltip: 'User actions',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUserActions(
    BuildContext context,
    WidgetRef ref,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isInactive = !user.isActive;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: cs.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // User header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          _roleColor(user.role).withValues(alpha: 0.12),
                      child: Text(
                        (user.name ?? user.email)
                            .characters
                            .first
                            .toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _roleColor(user.role),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name ?? user.email,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (user.name != null)
                            Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Send notification
                _UserActionTile(
                  icon: Icons.notifications_rounded,
                  title: 'Send Notification',
                  subtitle: 'Send a notification to this user',
                  color: cs.primary,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showNotificationDialog(context, ref);
                  },
                ),

                // Change role
                _UserActionTile(
                  icon: Icons.manage_accounts_rounded,
                  title: 'Change Role',
                  subtitle: 'Change this user\'s access role',
                  color: _roleColor(user.role),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showRoleDialog(context, ref);
                  },
                ),

                // Activate / Deactivate
                _UserActionTile(
                  icon: isInactive
                      ? Icons.person_add_alt_1_rounded
                      : Icons.person_off_rounded,
                  title: isInactive ? 'Activate User' : 'Deactivate User',
                  subtitle: isInactive
                      ? 'Allow this user to log in again'
                      : 'Prevent this user from logging in',
                  color: isInactive
                      ? const Color(0xFF94E2D5)
                      : const Color(0xFFF38BA8),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    if (isInactive) {
                      _confirmActivate(context, ref);
                    } else {
                      _confirmDeactivate(context, ref);
                    }
                  },
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Notification'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 300,
          ),
          child: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To: ${user.name ?? user.email}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Notification title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyController,
                maxLength: 500,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Notification message',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          )),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.send_rounded),
            label: const Text('Send'),
            onPressed: () async {
              final title = titleController.text.trim();
              final body = bodyController.text.trim();

              if (title.isEmpty || body.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Title and message are required.'),
                  ),
                );
                return;
              }

              Navigator.pop(ctx);

              final success =
                  await ref.read(adminProvider('raised').notifier).sendToUser(
                        user.id,
                        title,
                        body,
                      );

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Notification sent successfully.'
                        : 'Failed to send notification.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showRoleDialog(BuildContext context, WidgetRef ref) {
    String selected = user.role;

    final roles = [
      (
        value: 'USER',
        label: 'User',
        icon: Icons.person_outline_rounded,
      ),
      (
        value: 'ADMIN',
        label: 'Admin',
        icon: Icons.admin_panel_settings_outlined,
      ),
      (
        value: 'STAFF',
        label: 'Staff',
        icon: Icons.badge_outlined,
      ),
      (
        value: 'STORE',
        label: 'Store',
        icon: Icons.storefront_outlined,
      ),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final cs = Theme.of(context).colorScheme;

          return AlertDialog(
            title: Text(
              'Change Role',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    user.name ?? user.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...roles.map(
                  (role) {
                    final isSelected = selected == role.value;
                    final roleColor = _roleColor(role.value);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() => selected = role.value);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? roleColor.withValues(alpha: 0.10)
                                : cs.onSurface.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? roleColor.withValues(alpha: 0.5)
                                  : cs.onSurface.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Icon(
                                  role.icon,
                                  size: 20,
                                  color: roleColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  role.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                child: isSelected
                                    ? Icon(
                                        Icons.check_circle_rounded,
                                        key: const ValueKey('selected'),
                                        size: 21,
                                        color: roleColor,
                                      )
                                    : Icon(
                                        Icons.radio_button_unchecked_rounded,
                                        key: const ValueKey('unselected'),
                                        size: 21,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.25),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: selected == user.role
                    ? null
                    : () async {
                        Navigator.pop(ctx);

                        final result = await ref
                            .read(usersProvider.notifier)
                            .updateRole(user.id, selected);

                        if (!context.mounted) return;

                        if (result.success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'User Role changed successfully',
                              ),
                            ),
                          );
                        } else {
                          _showConflictSnackBar(context, result);
                        }
                      },
                child: const Text('Update Role'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmActivate(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Activate User'),
        content: Text(
          'Activate ${user.name ?? user.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              final result =
                  await ref.read(usersProvider.notifier).activateUser(user.id);
              if (!context.mounted) return;
              if (result.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User activated successfully'),
                  ),
                );
              } else if (context.mounted) {
                _showConflictSnackBar(context, result);
              }
            },
            child: const Text('Activate'),
          ),
        ],
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
              final result = await ref
                  .read(usersProvider.notifier)
                  .deactivateUser(user.id);
              if (!context.mounted) return;
              if (result.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User deactivated successfully'),
                  ),
                );
              } else if (context.mounted) {
                _showConflictSnackBar(context, result);
              }
            },
            child:
                const Text('Deactivate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showConflictSnackBar(BuildContext context, UserActionResult result) {
    if (result.conflict != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _ConflictSheet(
          userName: user.name ?? user.email,
          conflict: result.conflict!,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Action failed.'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
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

// ---------------------------------------------------------------------------
// Conflict bottom sheet
// ---------------------------------------------------------------------------

class _ConflictSheet extends StatefulWidget {
  final String userName;
  final UserParticipation conflict;

  const _ConflictSheet({required this.userName, required this.conflict});

  @override
  State<_ConflictSheet> createState() => _ConflictSheetState();
}

class _ConflictSheetState extends State<_ConflictSheet> {
  final _client = NetworkClient();

  // local mutable copies so items disappear after action
  late List<Request> _raisedRequests;
  late List<Request> _assignedRequests;
  late List<StoreRequest> _requestedSRs;
  late List<StoreRequest> _respondedSRs;

  @override
  void initState() {
    super.initState();
    _raisedRequests = List.of(widget.conflict.raisedRequests);
    _assignedRequests = List.of(widget.conflict.assignedRequests);
    _requestedSRs = List.of(widget.conflict.requestedStoreRequests);
    _respondedSRs = List.of(widget.conflict.respondedStoreRequests);
  }

  bool get _allResolved =>
      _raisedRequests.isEmpty &&
      _assignedRequests.isEmpty &&
      _requestedSRs.isEmpty &&
      _respondedSRs.isEmpty;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Unfinished work — ${widget.userName}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Resolve all items before retrying.',
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 12),
            if (_allResolved)
              Expanded(
                child: Center(
                  child: Text('All resolved. You may retry.',
                      style: TextStyle(color: cs.primary)),
                ),
              )
            else
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    if (_raisedRequests.isNotEmpty) ...[
                      _sectionHeader(cs, Icons.upload_rounded,
                          const Color(0xFF89B4FA), 'Raised by user'),
                      ..._raisedRequests.map((r) => _RequestItem(
                            request: r,
                            onDelete: () => _deleteRequest(r),
                            onReject: () => _rejectRequest(r),
                          )),
                    ],
                    if (_assignedRequests.isNotEmpty) ...[
                      _sectionHeader(cs, Icons.assignment_ind_rounded,
                          const Color(0xFFCBA6F7), 'Assigned to user'),
                      ..._assignedRequests.map((r) => _RequestItem(
                            request: r,
                            onDelete: () => _deleteRequest(r),
                            onReject: () => _rejectRequest(r),
                          )),
                    ],
                    if (_requestedSRs.isNotEmpty) ...[
                      _sectionHeader(cs, Icons.store_rounded,
                          const Color(0xFFF9E2AF), 'Store requests raised'),
                      ..._requestedSRs.map((sr) => _StoreRequestItem(
                            storeRequest: sr,
                            onDelete: () => _deleteStoreRequest(sr),
                          )),
                    ],
                    if (_respondedSRs.isNotEmpty) ...[
                      _sectionHeader(cs, Icons.reply_rounded,
                          const Color(0xFF94E2D5), 'Store requests responded'),
                      ..._respondedSRs.map((sr) => _StoreRequestItem(
                            storeRequest: sr,
                            onDelete: () => _deleteStoreRequest(sr),
                          )),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(
      ColorScheme cs, IconData icon, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Future<void> _deleteRequest(Request r) async {
    try {
      await _client.delete('/admin/request/${r.id}');
      setState(() {
        _raisedRequests.remove(r);
        _assignedRequests.remove(r);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Delete failed.')));
      }
    }
  }

  Future<void> _rejectRequest(Request r) async {
    try {
      await _client.put('/admin/reject/${r.id}',
          data: {'comment': 'Rejected by admin during user management.'});
      setState(() {
        _raisedRequests.remove(r);
        _assignedRequests.remove(r);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Reject failed.')));
      }
    }
  }

  Future<void> _deleteStoreRequest(StoreRequest sr) async {
    try {
      await _client.delete('/admin/store-request/${sr.id}');
      setState(() {
        _requestedSRs.remove(sr);
        _respondedSRs.remove(sr);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Delete failed.')));
      }
    }
  }
}

class _RequestItem extends StatelessWidget {
  final Request request;
  final VoidCallback onDelete;
  final VoidCallback onReject;

  const _RequestItem({
    required this.request,
    required this.onDelete,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${request.mainType} › ${request.subType}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${request.roomNo} · ${request.statusDisplayText}',
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.cancel_outlined,
                  size: 20, color: Color(0xFFF9E2AF)),
              tooltip: 'Reject',
              onPressed: onReject,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 20, color: Color(0xFFF38BA8)),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreRequestItem extends StatelessWidget {
  final StoreRequest storeRequest;
  final VoidCallback onDelete;

  const _StoreRequestItem({
    required this.storeRequest,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeRequest.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    storeRequest.statusDisplayText,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 20, color: Color(0xFFF38BA8)),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _UserActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cs.onSurface.withValues(alpha: 0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}