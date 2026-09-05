import 'package:cncc_portal/presentation/pages/admin/admin_archive_page.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_assigned_page.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_inprogress_page.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_raised_page.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_reassign_page.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_replied_page.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_rooms_page.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_types_page.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_users_page.dart';
import 'package:cncc_portal/presentation/pages/shared/pages/my_requests/my_requests_archive_page.dart';
import 'package:cncc_portal/presentation/pages/shared/pages/my_requests/my_requests_inprogress_page.dart';
import 'package:cncc_portal/presentation/pages/shared/pages/my_requests/my_requests_raised_page.dart';
import 'package:cncc_portal/presentation/pages/shared/pages/my_requests/my_requests_replied_page.dart';
import 'package:cncc_portal/presentation/pages/shared/pages/profile_page.dart';
import 'package:cncc_portal/presentation/pages/shared/widgets/request-form/request_form_dialog.dart';
import 'package:cncc_portal/presentation/providers/admin_provider.dart';
import 'package:cncc_portal/presentation/providers/auth_provider.dart';
import 'package:cncc_portal/presentation/providers/my_requests_provider.dart';
import 'package:cncc_portal/presentation/providers/rooms_provider.dart';
import 'package:cncc_portal/presentation/providers/types_provider.dart';
import 'package:cncc_portal/presentation/providers/users_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _AdminTab {
  raised,
  replied,
  assigned,
  reassignRequested,
  inprogress,
  archive,
  manageUsers,
  manageTypes,
  manageRooms,
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

class _AdminHomePageState extends ConsumerState<AdminHomePage>
    with WidgetsBindingObserver {
  _AdminTab _tab = _AdminTab.raised;

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
      case _AdminTab.raised:
        ref.invalidate(adminProvider('raised'));
      case _AdminTab.replied:
        ref.invalidate(adminProvider('replied'));
      case _AdminTab.assigned:
        ref.invalidate(adminProvider('assigned'));
      case _AdminTab.reassignRequested:
        ref.invalidate(adminProvider('reassign-requested'));
      case _AdminTab.inprogress:
        ref.invalidate(adminProvider('inprogress'));
      case _AdminTab.archive:
        ref.invalidate(adminProvider('archive'));
      case _AdminTab.myRaised:
        ref.invalidate(myRequestsProvider('raised'));
      case _AdminTab.myReplied:
        ref.invalidate(myRequestsProvider('replied'));
      case _AdminTab.myInProgress:
        ref.invalidate(myRequestsProvider('inprogress'));
      case _AdminTab.myArchive:
        ref.invalidate(myRequestsProvider('archive'));
      case _AdminTab.manageUsers:
        ref.invalidate(usersProvider);
      case _AdminTab.manageTypes:
        ref.invalidate(mainTypesProvider);
        ref.invalidate(subTypesProvider);
      case _AdminTab.manageRooms:
        ref.invalidate(roomsProvider);
      case _AdminTab.profile:
        break;
    }
  }

  void _navigateTo(_AdminTab tab) {
    setState(() => _tab = tab);
    Navigator.pop(context);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _invalidateCurrentTab());
  }

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
      case _AdminTab.manageRooms:
        return 'Manage Rooms';
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
      case _AdminTab.manageRooms:
        return const AdminRoomsPage();
      case _AdminTab.myRaised:
        return const MyRequestsRaisedPage();
      case _AdminTab.myReplied:
        return const MyRequestsRepliedPage();
      case _AdminTab.myInProgress:
        return const MyRequestsInProgressPage();
      case _AdminTab.myArchive:
        return const MyRequestsArchivePage();
      case _AdminTab.profile:
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
          (_AdminTab.manageRooms, Icons.door_front_door_rounded, 'Rooms'),
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
