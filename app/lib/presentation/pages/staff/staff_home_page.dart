import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/presentation/providers/auth_provider.dart';
import 'package:cncc_portal/presentation/providers/my_requests_provider.dart';
import 'package:cncc_portal/presentation/providers/types_provider.dart';
import 'package:cncc_portal/presentation/pages/shared/profile_page.dart';
import 'package:cncc_portal/presentation/pages/staff/staff_assigned_page.dart';
import 'package:cncc_portal/presentation/pages/staff/staff_inprogress_page.dart';
import 'package:cncc_portal/presentation/pages/staff/staff_archive_page.dart';
import 'package:cncc_portal/presentation/pages/user/user_raised_page.dart';
import 'package:cncc_portal/presentation/pages/user/user_replied_page.dart';
import 'package:cncc_portal/presentation/pages/user/user_inprogress_page.dart';
import 'package:cncc_portal/presentation/pages/user/user_archive_page.dart';

enum _StaffTab {
  assigned,
  inprogress,
  archive,
  myRaised,
  myReplied,
  myInProgress,
  myArchive,
  profile,
}

class StaffHomePage extends ConsumerStatefulWidget {
  const StaffHomePage({super.key});

  @override
  ConsumerState<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends ConsumerState<StaffHomePage> {
  _StaffTab _tab = _StaffTab.assigned;

  String get _title {
    switch (_tab) {
      case _StaffTab.assigned:
        return 'Assigned to Me';
      case _StaffTab.inprogress:
        return 'In Progress';
      case _StaffTab.archive:
        return 'My Archive';
      case _StaffTab.myRaised:
        return 'My Raised';
      case _StaffTab.myReplied:
        return 'Needs Response';
      case _StaffTab.myInProgress:
        return 'My In Progress';
      case _StaffTab.myArchive:
        return 'My Archive';
      case _StaffTab.profile:
        return 'Profile';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final userName = user?.name ?? user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      drawer: _StaffDrawer(
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
        _StaffTab.myRaised,
        _StaffTab.myReplied,
        _StaffTab.myInProgress,
        _StaffTab.myArchive,
      ].contains(_tab);

  Widget _buildBody() {
    switch (_tab) {
      case _StaffTab.assigned:
        return const StaffAssignedPage();
      case _StaffTab.inprogress:
        return const StaffInProgressPage();
      case _StaffTab.archive:
        return const StaffArchivePage();
      case _StaffTab.myRaised:
        return const UserRaisedPage();
      case _StaffTab.myReplied:
        return const UserRepliedPage();
      case _StaffTab.myInProgress:
        return const UserInProgressPage();
      case _StaffTab.myArchive:
        return const UserArchivePage();
      case _StaffTab.profile:
        return const ProfilePage();
    }
  }

  void _showNewRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _StaffNewRequestDialog(
        onSuccess: () => ref.invalidate(myRequestsProvider('raised')),
      ),
    );
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────

class _StaffDrawer extends StatelessWidget {
  final _StaffTab currentTab;
  final String userName;
  final void Function(_StaffTab) onNavigate;

  const _StaffDrawer({
    required this.currentTab,
    required this.userName,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final sections = [
      (
        title: 'ASSIGNED WORK',
        items: [
          (_StaffTab.assigned, Icons.assignment_ind_rounded, 'Assigned to Me'),
          (_StaffTab.inprogress, Icons.pending_rounded, 'In Progress'),
          (_StaffTab.archive, Icons.task_alt_rounded, 'Archive'),
        ]
      ),
      (
        title: 'MY REQUESTS',
        items: [
          (_StaffTab.myRaised, Icons.inbox_rounded, 'Raised'),
          (_StaffTab.myReplied, Icons.reply_all_rounded, 'Needs Response'),
          (
            _StaffTab.myInProgress,
            Icons.pending_actions_rounded,
            'In Progress'
          ),
          (_StaffTab.myArchive, Icons.archive_rounded, 'Archive'),
        ]
      ),
      (
        title: 'ACCOUNT',
        items: [
          (_StaffTab.profile, Icons.account_circle_rounded, 'Profile'),
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
                        Text('Staff',
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
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── New Request Dialog ────────────────────────────────────────────────────────

class _StaffNewRequestDialog extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  const _StaffNewRequestDialog({required this.onSuccess});

  @override
  ConsumerState<_StaffNewRequestDialog> createState() =>
      _StaffNewRequestDialogState();
}

class _StaffNewRequestDialogState
    extends ConsumerState<_StaffNewRequestDialog> {
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
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.trim().length != 10) return '10 digits required';
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
