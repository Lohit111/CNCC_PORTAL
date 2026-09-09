import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/presentation/providers/auth_provider.dart';
import 'package:cncc_portal/presentation/providers/store_provider.dart';
import 'package:cncc_portal/presentation/pages/shared/pages/profile_page.dart';
import 'package:cncc_portal/presentation/pages/store/store_pending_page.dart';
import 'package:cncc_portal/presentation/pages/store/store_approved_page.dart';
import 'package:cncc_portal/presentation/pages/store/store_archive_page.dart';

enum _StoreTab { pending, approved, archive, profile }

class StoreHomePage extends ConsumerStatefulWidget {
  const StoreHomePage({super.key});

  @override
  ConsumerState<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends ConsumerState<StoreHomePage>
    with WidgetsBindingObserver {
  _StoreTab _tab = _StoreTab.pending;

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
      case _StoreTab.pending:
        ref.invalidate(storeProvider('pending'));
      case _StoreTab.approved:
        ref.invalidate(storeProvider('approved'));
      case _StoreTab.archive:
        ref.invalidate(storeProvider('archive'));
      case _StoreTab.profile:
        break;
    }
  }

  void _navigateTo(_StoreTab tab) {
    setState(() => _tab = tab);
    Navigator.pop(context);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _invalidateCurrentTab());
  }

  String get _title {
    switch (_tab) {
      case _StoreTab.pending:
        return 'Pending Requests';
      case _StoreTab.approved:
        return 'Approved Requests';
      case _StoreTab.archive:
        return 'Archive';
      case _StoreTab.profile:
        return 'Profile';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final userName = user?.name ?? user?.email ?? '';

    final pendingCount =
        ref.watch(storeProvider('pending')).valueOrNull?.total ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: Builder(
          builder: (ctx) => Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
              if (pendingCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF89B4FA),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      drawer: _StoreDrawer(
        currentTab: _tab,
        userName: userName,
        pendingCount: pendingCount,
        onNavigate: _navigateTo,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case _StoreTab.pending:
        return const StorePendingPage();
      case _StoreTab.approved:
        return const StoreApprovedPage();
      case _StoreTab.archive:
        return const StoreArchivePage();
      case _StoreTab.profile:
        return const ProfilePage();
    }
  }
}

class _StoreDrawer extends StatelessWidget {
  final _StoreTab currentTab;
  final String userName;
  final int pendingCount;
  final void Function(_StoreTab) onNavigate;

  const _StoreDrawer({
    required this.currentTab,
    required this.userName,
    required this.pendingCount,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final sections = [
      (
        title: 'STORE REQUESTS',
        items: [
          (_StoreTab.pending, Icons.pending_rounded, 'Pending', pendingCount),
          (_StoreTab.approved, Icons.verified_rounded, 'Approved', 0),
          (_StoreTab.archive, Icons.archive_rounded, 'Archive', 0),
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
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onNavigate(_StoreTab.profile),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: cs.primary.withValues(alpha: 0.15),
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: TextStyle(
                                  fontSize: 15,
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
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: cs.onSurface.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                  ),
                ),
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
                        badge: item.$4,
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
  final int badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.badge,
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
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
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
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAB387),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
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
