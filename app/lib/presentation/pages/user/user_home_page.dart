import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/type_entity.dart';
import 'package:cncc_portal/presentation/pages/shared/create_request_dialog.dart';
import 'package:cncc_portal/presentation/pages/shared/profile_page.dart';
import 'package:cncc_portal/presentation/pages/user/active_requests_page.dart';
import 'package:cncc_portal/presentation/pages/user/replied_requests_user_page.dart';
import 'package:cncc_portal/presentation/pages/user/completed_requests_user_page.dart';

// ── Page IDs ──────────────────────────────────────────────────────────────────
enum _UserPage {
  active,
  replied,
  completed,
  profile,
}

// ── Sidebar item model ────────────────────────────────────────────────────────
class _SidebarItem {
  final _UserPage page;
  final IconData icon;
  final String label;

  const _SidebarItem(this.page, this.icon, this.label);
}

const _sections = [
  (
    title: 'My Requests',
    items: [
      _SidebarItem(_UserPage.active, Icons.pending_actions_rounded, 'Active'),
      _SidebarItem(_UserPage.replied, Icons.reply_rounded, 'Needs Response'),
      _SidebarItem(_UserPage.completed, Icons.task_alt_rounded, 'Completed'),
    ],
  ),
  (
    title: 'Account',
    items: [
      _SidebarItem(_UserPage.profile, Icons.account_circle_rounded, 'Profile'),
    ],
  ),
];

// ── Home page ─────────────────────────────────────────────────────────────────
class UserHomePage extends ConsumerStatefulWidget {
  const UserHomePage({super.key});

  @override
  ConsumerState<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends ConsumerState<UserHomePage> {
  final _networkClient = NetworkClient();
  _UserPage _currentPage = _UserPage.active;
  final _activeRequestsKey = GlobalKey<ActiveRequestsPageState>();

  String get _currentTitle {
    for (final section in _sections) {
      for (final item in section.items) {
        if (item.page == _currentPage) return item.label;
      }
    }
    return 'CNCC Portal';
  }

  void _navigate(_UserPage page) {
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
      setState(() => _currentPage = _UserPage.active);
      _activeRequestsKey.currentState?.refresh();
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
      drawer: _UserDrawer(
        currentPage: _currentPage,
        onNavigate: _navigate,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRequestDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Request',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentPage) {
      case _UserPage.active:
        return ActiveRequestsPage(key: _activeRequestsKey);
      case _UserPage.replied:
        return const RepliedRequestsUserPage();
      case _UserPage.completed:
        return const CompletedRequestsUserPage();
      case _UserPage.profile:
        return const ProfilePage();
    }
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────
class _UserDrawer extends StatelessWidget {
  final _UserPage currentPage;
  final void Function(_UserPage) onNavigate;

  const _UserDrawer({
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
                    child:
                        Icon(Icons.person_rounded, color: cs.primary, size: 22),
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
                        'User',
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
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
