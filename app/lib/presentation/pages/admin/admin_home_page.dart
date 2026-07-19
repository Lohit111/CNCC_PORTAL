import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/type_entity.dart';
import 'package:cncc_portal/presentation/pages/shared/create_request_dialog.dart';
import 'package:cncc_portal/presentation/pages/shared/my_requests_page.dart';
import 'package:cncc_portal/presentation/pages/shared/profile_page.dart';
import 'package:cncc_portal/presentation/pages/admin/raised_requests_page.dart';
import 'package:cncc_portal/presentation/pages/admin/replied_requests_page.dart';
import 'package:cncc_portal/presentation/pages/admin/assigned_requests_page.dart';
import 'package:cncc_portal/presentation/pages/admin/completed_requests_page.dart';
import 'package:cncc_portal/presentation/pages/admin/manage_roles_page.dart';
import 'package:cncc_portal/presentation/pages/admin/manage_types_page.dart';

// ── Page IDs ─────────────────────────────────────────────────────────────────
enum _AdminPage {
  raised,
  replied,
  assigned,
  completed,
  manageRoles,
  manageTypes,
  myRequests,
  profile,
}

// ── Sidebar item model ────────────────────────────────────────────────────────
class _SidebarItem {
  final _AdminPage page;
  final IconData icon;
  final String label;

  const _SidebarItem(this.page, this.icon, this.label);
}

// ── Section model ─────────────────────────────────────────────────────────────
class _SidebarSection {
  final String title;
  final List<_SidebarItem> items;

  const _SidebarSection(this.title, this.items);
}

const _sections = [
  _SidebarSection('Requests', [
    _SidebarItem(_AdminPage.raised, Icons.fiber_new_rounded, 'Raised'),
    _SidebarItem(_AdminPage.replied, Icons.reply_rounded, 'Replied'),
    _SidebarItem(_AdminPage.assigned, Icons.assignment_ind_rounded, 'Assigned'),
    _SidebarItem(_AdminPage.completed, Icons.task_alt_rounded, 'Archive'),
  ]),
  _SidebarSection('Management', [
    _SidebarItem(
        _AdminPage.manageRoles, Icons.manage_accounts_rounded, 'Roles'),
    _SidebarItem(_AdminPage.manageTypes, Icons.category_rounded, 'Types'),
  ]),
  _SidebarSection('Personal', [
    _SidebarItem(_AdminPage.myRequests, Icons.person_rounded, 'My Requests'),
    _SidebarItem(_AdminPage.profile, Icons.account_circle_rounded, 'Profile'),
  ]),
];

// ── Home page ─────────────────────────────────────────────────────────────────
class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  final _networkClient = NetworkClient();
  _AdminPage _currentPage = _AdminPage.raised;
  final _myRequestsKey = GlobalKey<MyRequestsPageState>();

  String get _currentTitle {
    for (final section in _sections) {
      for (final item in section.items) {
        if (item.page == _currentPage) return item.label;
      }
    }
    return 'Admin';
  }

  void _navigate(_AdminPage page) {
    setState(() => _currentPage = page);
    Navigator.pop(context); // close drawer
  }

  void _showCreateRequestDialog() async {
    final mainTypes = await _loadMainTypes();
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateRequestDialog(mainTypes: mainTypes),
    );

    if (result == true && mounted) {
      setState(() => _currentPage = _AdminPage.myRequests);
      _myRequestsKey.currentState?.refresh();
    }
  }

  Future<List<MainType>> _loadMainTypes() async {
    try {
      final response = await _networkClient.get('/types/main');
      return (response.data as List)
          .map((json) => MainType.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () async {
              await fb.FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      drawer: _AdminDrawer(
        currentPage: _currentPage,
        onNavigate: _navigate,
      ),
      body: _buildBody(),
      floatingActionButton: _currentPage == _AdminPage.myRequests
          ? FloatingActionButton.extended(
              onPressed: _showCreateRequestDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Request',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_currentPage) {
      case _AdminPage.raised:
        return const RaisedRequestsPage();
      case _AdminPage.replied:
        return const RepliedRequestsPage();
      case _AdminPage.assigned:
        return const AssignedRequestsPage();
      case _AdminPage.completed:
        return const CompletedRequestsPage();
      case _AdminPage.manageRoles:
        return const ManageRolesPage();
      case _AdminPage.manageTypes:
        return const ManageTypesPage();
      case _AdminPage.myRequests:
        return MyRequestsPage(key: _myRequestsKey);
      case _AdminPage.profile:
        return const ProfilePage();
    }
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────
class _AdminDrawer extends StatelessWidget {
  final _AdminPage currentPage;
  final void Function(_AdminPage) onNavigate;

  const _AdminDrawer({
    required this.currentPage,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: cs.surfaceContainerLow,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.admin_panel_settings_rounded,
                        color: cs.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CNCC Portal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: cs.onSurface.withValues(alpha: 0.08)),
            const SizedBox(height: 4),

            // Sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final section in _sections) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                      child: Text(
                        section.title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    for (final item in section.items)
                      _DrawerTile(
                        item: item,
                        isSelected: currentPage == item.page,
                        onTap: () => onNavigate(item.page),
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
  final _SidebarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.item,
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
            ? cs.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
