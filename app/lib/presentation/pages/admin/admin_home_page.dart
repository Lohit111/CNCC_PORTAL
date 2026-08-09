import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/presentation/providers/auth_provider.dart';
import 'package:cncc_portal/presentation/providers/my_requests_provider.dart';
import 'package:cncc_portal/presentation/providers/types_provider.dart';
import 'package:cncc_portal/presentation/pages/shared/profile_page.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_raised_page.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_replied_page.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_assigned_page.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_reassign_page.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_inprogress_page.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_archive_page.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_users_page.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_types_page.dart';
import 'package:cncc_portal/presentation/pages/user/user_raised_page.dart';
import 'package:cncc_portal/presentation/pages/user/user_replied_page.dart';
import 'package:cncc_portal/presentation/pages/user/user_inprogress_page.dart';
import 'package:cncc_portal/presentation/pages/user/user_archive_page.dart';

enum _AdminTab {
  raised,
  replied,
  assigned,
  reassignRequested,
  inprogress,
  archive,
  manageUsers,
  manageTypes,
  myRaised,
  myReplied,
  myInProgress,
  myArchive,
  profile,
}

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  _AdminTab _tab = _AdminTab.raised;

  String get _title {
    switch (_tab) {
      case _AdminTab.raised:
        return 'Raised Requests';
      case _AdminTab.replied:
        return 'Replied Requests';
      case _AdminTab.assigned:
        return 'Assigned Requests';
      case _AdminTab.reassignRequested:
        return 'Reassign Requested';
      case _AdminTab.inprogress:
        return 'In Progress';
      case _AdminTab.archive:
        return 'Archive';
      case _AdminTab.manageUsers:
        return 'Manage Users';
      case _AdminTab.manageTypes:
        return 'Manage Types';
      case _AdminTab.myRaised:
        return 'My Raised';
      case _AdminTab.myReplied:
        return 'My Needs Response';
      case _AdminTab.myInProgress:
        return 'My In Progress';
      case _AdminTab.myArchive:
        return 'My Archive';
      case _AdminTab.profile:
        return 'Profile';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final userName = user?.name ?? user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      drawer: _AdminDrawer(
        currentTab: _tab,
        userName: userName,
        onNavigate: (tab) {
          setState(() => _tab = tab);
          Navigator.pop(context);
        },
      ),
      body: _buildBody(),
      floatingActionButton: _isMyRequestsTab
          ? FloatingActionButton.extended(
              onPressed: () => _showNewRequestDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Request',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  bool get _isMyRequestsTab => [
        _AdminTab.myRaised,
        _AdminTab.myReplied,
        _AdminTab.myInProgress,
        _AdminTab.myArchive,
      ].contains(_tab);

  Widget _buildBody() {
    switch (_tab) {
      case _AdminTab.raised:
        return const AdminRaisedPage();
      case _AdminTab.replied:
        return const AdminRepliedPage();
      case _AdminTab.assigned:
        return const AdminAssignedPage();
      case _AdminTab.reassignRequested:
        return const AdminReassignPage();
      case _AdminTab.inprogress:
        return const AdminInProgressPage();
      case _AdminTab.archive:
        return const AdminArchivePage();
      case _AdminTab.manageUsers:
        return const AdminUsersPage();
      case _AdminTab.manageTypes:
        return const AdminTypesPage();
      case _AdminTab.myRaised:
        return const UserRaisedPage();
      case _AdminTab.myReplied:
        return const UserRepliedPage();
      case _AdminTab.myInProgress:
        return const UserInProgressPage();
      case _AdminTab.myArchive:
        return const UserArchivePage();
      case _AdminTab.profile:
        return const ProfilePage();
    }
  }

  void _showNewRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AdminNewRequestDialog(
        onSuccess: () => ref.invalidate(myRequestsProvider('raised')),
      ),
    );
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────

class _AdminDrawer extends StatelessWidget {
  final _AdminTab currentTab;
  final String userName;
  final void Function(_AdminTab) onNavigate;

  const _AdminDrawer({
    required this.currentTab,
    required this.userName,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final sections = [
      (
        title: 'ALL REQUESTS',
        items: [
          (_AdminTab.raised, Icons.fiber_new_rounded, 'Raised'),
          (_AdminTab.replied, Icons.reply_rounded, 'Replied'),
          (_AdminTab.assigned, Icons.assignment_ind_rounded, 'Assigned'),
          (
            _AdminTab.reassignRequested,
            Icons.swap_horiz_rounded,
            'Reassign Requested'
          ),
          (_AdminTab.inprogress, Icons.pending_rounded, 'In Progress'),
          (_AdminTab.archive, Icons.task_alt_rounded, 'Archive'),
        ]
      ),
      (
        title: 'MANAGEMENT',
        items: [
          (_AdminTab.manageUsers, Icons.manage_accounts_rounded, 'Users'),
          (_AdminTab.manageTypes, Icons.category_rounded, 'Types'),
        ]
      ),
      (
        title: 'MY REQUESTS',
        items: [
          (_AdminTab.myRaised, Icons.inbox_rounded, 'Raised'),
          (_AdminTab.myReplied, Icons.reply_all_rounded, 'Needs Response'),
          (
            _AdminTab.myInProgress,
            Icons.pending_actions_rounded,
            'In Progress'
          ),
          (_AdminTab.myArchive, Icons.archive_rounded, 'Archive'),
        ]
      ),
      (
        title: 'ACCOUNT',
        items: [
          (_AdminTab.profile, Icons.account_circle_rounded, 'Profile'),
        ]
      ),
    ];

    return Drawer(
      backgroundColor: cs.surfaceContainerLow,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.primary.withValues(alpha: 0.15),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: cs.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CNCC Portal',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface)),
                        Text('Admin',
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.45))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: cs.onSurface.withValues(alpha: 0.08)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final section in sections) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                      child: Text(section.title,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: cs.onSurface.withValues(alpha: 0.5))),
                    ),
                    for (final item in section.items)
                      _DrawerTile(
                        icon: item.$2,
                        label: item.$3,
                        isSelected: currentTab == item.$1,
                        onTap: () => onNavigate(item.$1),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isSelected
            ? cs.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: isSelected
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.55)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? cs.primary
                              : cs.onSurface.withValues(alpha: 0.8))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── New Request Dialog (reuses user dialog logic) ─────────────────────────────

class _AdminNewRequestDialog extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  const _AdminNewRequestDialog({required this.onSuccess});

  @override
  ConsumerState<_AdminNewRequestDialog> createState() =>
      _AdminNewRequestDialogState();
}

class _AdminNewRequestDialogState
    extends ConsumerState<_AdminNewRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _roomController = TextEditingController();
  final _phoneController = TextEditingController();
  int? _selectedMainId;
  int? _selectedSubId;
  String? _selectedMainName;
  String? _selectedSubName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descController.dispose();
    _roomController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mainTypesAsync = ref.watch(mainTypesProvider);
    return AlertDialog(
      title: const Text('New Request'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                mainTypesAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (mainTypes) => DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Main Type'),
                    value: _selectedMainId,
                    items: mainTypes
                        .map((t) =>
                            DropdownMenuItem(value: t.id, child: Text(t.name)))
                        .toList(),
                    onChanged: (val) {
                      final mt = mainTypes.firstWhere((t) => t.id == val);
                      setState(() {
                        _selectedMainId = val;
                        _selectedMainName = mt.name;
                        _selectedSubId = null;
                        _selectedSubName = null;
                      });
                    },
                    validator: (v) => v == null ? 'Select a main type' : null,
                  ),
                ),
                const SizedBox(height: 12),
                if (_selectedMainId != null)
                  Consumer(builder: (_, ref, __) {
                    final subAsync =
                        ref.watch(subTypesProvider(_selectedMainId!));
                    return subAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error: $e'),
                      data: (subs) => DropdownButtonFormField<int>(
                        decoration:
                            const InputDecoration(labelText: 'Sub Type'),
                        value: _selectedSubId,
                        items: subs
                            .map((t) => DropdownMenuItem(
                                value: t.id, child: Text(t.name)))
                            .toList(),
                        onChanged: (val) {
                          final st = subs.firstWhere((t) => t.id == val);
                          setState(() {
                            _selectedSubId = val;
                            _selectedSubName = st.name;
                          });
                        },
                        validator: (v) =>
                            v == null ? 'Select a sub type' : null,
                      ),
                    );
                  }),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _roomController,
                  decoration: const InputDecoration(labelText: 'Room No'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone No'),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  validator: (v) {
                    final phone = v?.trim() ?? '';
                    if (phone.isEmpty) return 'Required';
                    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
                      return '10 digits required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Submit'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMainName == null || _selectedSubName == null) return;
    setState(() => _isSubmitting = true);
    final success =
        await ref.read(myRequestsProvider('raised').notifier).createRequest(
              mainType: _selectedMainName!,
              subType: _selectedSubName!,
              description: _descController.text.trim(),
              roomNo: _roomController.text.trim(),
              phoneNo: _phoneController.text.trim(),
            );
    if (mounted) {
      Navigator.pop(context);
      if (success) widget.onSuccess();
    }
  }
}
