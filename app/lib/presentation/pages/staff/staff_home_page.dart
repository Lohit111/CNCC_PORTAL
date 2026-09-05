import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/presentation/providers/auth_provider.dart';
import 'package:cncc_portal/presentation/providers/my_requests_provider.dart';
import 'package:cncc_portal/presentation/providers/staff_provider.dart';
import 'package:cncc_portal/presentation/pages/shared/pages/profile_page.dart';
import 'package:cncc_portal/presentation/pages/shared/widgets/request-form/request_form_dialog.dart';
import 'package:cncc_portal/presentation/pages/staff/staff_assigned_page.dart';
import 'package:cncc_portal/presentation/pages/staff/staff_inprogress_page.dart';
import 'package:cncc_portal/presentation/pages/staff/staff_archive_page.dart';
import 'package:cncc_portal/presentation/pages/shared/pages/my_requests/my_requests_raised_page.dart';
import 'package:cncc_portal/presentation/pages/shared/pages/my_requests/my_requests_replied_page.dart';
import 'package:cncc_portal/presentation/pages/shared/pages/my_requests/my_requests_inprogress_page.dart';
import 'package:cncc_portal/presentation/pages/shared/pages/my_requests/my_requests_archive_page.dart';

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

class _StaffHomePageState extends ConsumerState<StaffHomePage>
    with WidgetsBindingObserver {
  _StaffTab _tab = _StaffTab.assigned;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _invalidateCurrentTab();
    }
  }

  void _invalidateCurrentTab() {
    switch (_tab) {
      case _StaffTab.assigned:
        ref.invalidate(staffProvider('assigned'));
      case _StaffTab.inprogress:
        ref.invalidate(staffProvider('inprogress'));
      case _StaffTab.archive:
        ref.invalidate(staffProvider('archive'));
      case _StaffTab.myRaised:
        ref.invalidate(myRequestsProvider('raised'));
      case _StaffTab.myReplied:
        ref.invalidate(myRequestsProvider('replied'));
      case _StaffTab.myInProgress:
        ref.invalidate(myRequestsProvider('inprogress'));
      case _StaffTab.myArchive:
        ref.invalidate(myRequestsProvider('archive'));
      case _StaffTab.profile:
        break;
    }
  }

  void _navigateTo(_StaffTab tab) {
    setState(() => _tab = tab);
    Navigator.pop(context);
    // Invalidate after setState so the new tab's provider rebuilds fresh
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _invalidateCurrentTab());
  }

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
        onNavigate: _navigateTo,
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
        return const MyRequestsRaisedPage();
      case _StaffTab.myReplied:
        return const MyRequestsRepliedPage();
      case _StaffTab.myInProgress:
        return const MyRequestsInProgressPage();
      case _StaffTab.myArchive:
        return const MyRequestsArchivePage();
      case _StaffTab.profile:
        return const ProfilePage();
    }
  }

  void _showNewRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => RequestFormDialog(
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
