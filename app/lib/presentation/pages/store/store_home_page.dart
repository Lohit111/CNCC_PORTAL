import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cncc_portal/presentation/pages/shared/profile_page.dart';
import 'package:cncc_portal/presentation/pages/store/pending_store_requests_page.dart';
import 'package:cncc_portal/presentation/pages/store/approved_store_requests_page.dart';
import 'package:cncc_portal/presentation/pages/store/fulfilled_rejected_page.dart';

// ── Page IDs ──────────────────────────────────────────────────────────────────
enum _StorePage {
  pending,
  approved,
  completed,
  profile,
}

// ── Sidebar item model ────────────────────────────────────────────────────────
class _SidebarItem {
  final _StorePage page;
  final IconData icon;
  final String label;

  const _SidebarItem(this.page, this.icon, this.label);
}

const _sections = [
  (
    title: 'Store Requests',
    items: [
      _SidebarItem(_StorePage.pending, Icons.pending_rounded, 'Pending'),
      _SidebarItem(_StorePage.approved, Icons.check_circle_rounded, 'Approved'),
      _SidebarItem(_StorePage.completed, Icons.task_alt_rounded, 'Completed'),
    ],
  ),
  (
    title: 'Account',
    items: [
      _SidebarItem(_StorePage.profile, Icons.account_circle_rounded, 'Profile'),
    ],
  ),
];

// ── Home page ─────────────────────────────────────────────────────────────────
class StoreHomePage extends ConsumerStatefulWidget {
  const StoreHomePage({super.key});

  @override
  ConsumerState<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends ConsumerState<StoreHomePage> {
  _StorePage _currentPage = _StorePage.pending;

  String get _currentTitle {
    for (final section in _sections) {
      for (final item in section.items) {
        if (item.page == _currentPage) return item.label;
      }
    }
    return 'Store Dashboard';
  }

  void _navigate(_StorePage page) {
    setState(() => _currentPage = page);
    Navigator.pop(context); // close drawer
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
      drawer: _StoreDrawer(
        currentPage: _currentPage,
        onNavigate: _navigate,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentPage) {
      case _StorePage.pending:
        return const PendingStoreRequestsPage();
      case _StorePage.approved:
        return const ApprovedStoreRequestsPage();
      case _StorePage.completed:
        return const FulfilledRejectedPage();
      case _StorePage.profile:
        return const ProfilePage();
    }
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────
class _StoreDrawer extends StatelessWidget {
  final _StorePage currentPage;
  final void Function(_StorePage) onNavigate;

  const _StoreDrawer({
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
                        Icon(Icons.store_rounded, color: cs.primary, size: 22),
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
                        'Store',
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
