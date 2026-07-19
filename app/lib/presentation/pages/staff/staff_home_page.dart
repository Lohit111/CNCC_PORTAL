import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/type_entity.dart';
import 'package:cncc_portal/presentation/pages/shared/create_request_dialog.dart';
import 'package:cncc_portal/presentation/pages/shared/my_requests_page.dart';
import 'package:cncc_portal/presentation/pages/staff/assigned_to_me_page.dart';
import 'package:cncc_portal/presentation/pages/staff/in_progress_page.dart';
import 'package:cncc_portal/presentation/pages/staff/completed_by_me_page.dart';
import 'package:cncc_portal/presentation/pages/staff/my_store_requests_page.dart';

// ── Page IDs ──────────────────────────────────────────────────────────────────
enum _StaffPage {
  assigned,
  inProgress,
  completed,
  storeRequests,
  myRequests,
}

// ── Sidebar item model ────────────────────────────────────────────────────────
class _SidebarItem {
  final _StaffPage page;
  final IconData icon;
  final String label;

  const _SidebarItem(this.page, this.icon, this.label);
}

const _sections = [
  (
    title: 'Work',
    items: [
      _SidebarItem(
          _StaffPage.assigned, Icons.assignment_ind_rounded, 'Assigned to Me'),
      _SidebarItem(_StaffPage.inProgress, Icons.work_rounded, 'In Progress'),
      _SidebarItem(
          _StaffPage.completed, Icons.check_circle_rounded, 'Completed'),
      _SidebarItem(_StaffPage.storeRequests, Icons.inventory_2_rounded,
          'Store Requests'),
    ],
  ),
  (
    title: 'Personal',
    items: [
      _SidebarItem(_StaffPage.myRequests, Icons.person_rounded, 'My Requests'),
    ],
  ),
];

// ── Home page ─────────────────────────────────────────────────────────────────
class StaffHomePage extends ConsumerStatefulWidget {
  const StaffHomePage({super.key});

  @override
  ConsumerState<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends ConsumerState<StaffHomePage> {
  final _networkClient = NetworkClient();
  _StaffPage _currentPage = _StaffPage.assigned;
  final _myRequestsKey = GlobalKey<MyRequestsPageState>();

  String get _currentTitle {
    for (final section in _sections) {
      for (final item in section.items) {
        if (item.page == _currentPage) return item.label;
      }
    }
    return 'Staff';
  }

  void _navigate(_StaffPage page) {
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
      setState(() => _currentPage = _StaffPage.myRequests);
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
      drawer: _StaffDrawer(
        currentPage: _currentPage,
        onNavigate: _navigate,
      ),
      body: _buildBody(),
      floatingActionButton: _currentPage == _StaffPage.myRequests
          ? FloatingActionButton.extended(
              onPressed: _showCreateRequestDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New Request',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_currentPage) {
      case _StaffPage.assigned:
        return const AssignedToMePage();
      case _StaffPage.inProgress:
        return const InProgressPage();
      case _StaffPage.completed:
        return const CompletedByMePage();
      case _StaffPage.storeRequests:
        return const MyStoreRequestsPage();
      case _StaffPage.myRequests:
        return MyRequestsPage(key: _myRequestsKey);
    }
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────
class _StaffDrawer extends StatelessWidget {
  final _StaffPage currentPage;
  final void Function(_StaffPage) onNavigate;

  const _StaffDrawer({
    required this.currentPage,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
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
                    child: Icon(Icons.engineering_rounded,
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
                        'Staff',
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
                          color: cs.onSurface.withValues(alpha: 0.35),
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
