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
                final result = await ref
                    .read(usersProvider.notifier)
                    .updateRole(user.id, selected);
                if (!result.success && context.mounted) {
                  _showConflictSnackBar(context, result);
                }
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
              final result = await ref
                  .read(usersProvider.notifier)
                  .deactivateUser(user.id);
              if (!result.success && context.mounted) {
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

// ---------------------------------------------------------------------------
// Pagination row
// ---------------------------------------------------------------------------

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
