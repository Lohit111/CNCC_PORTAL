import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/presentation/providers/auth_provider.dart';
import 'package:cncc_portal/presentation/providers/my_requests_provider.dart';
import 'package:cncc_portal/presentation/providers/types_provider.dart';
import 'package:cncc_portal/presentation/pages/shared/profile_page.dart';
import 'package:cncc_portal/presentation/pages/user/user_raised_page.dart';
import 'package:cncc_portal/presentation/pages/user/user_replied_page.dart';
import 'package:cncc_portal/presentation/pages/user/user_inprogress_page.dart';
import 'package:cncc_portal/presentation/pages/user/user_archive_page.dart';

enum _UserTab { raised, replied, inprogress, archive, profile }

class UserHomePage extends ConsumerStatefulWidget {
  const UserHomePage({super.key});

  @override
  ConsumerState<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends ConsumerState<UserHomePage> {
  _UserTab _tab = _UserTab.raised;

  String get _title {
    switch (_tab) {
      case _UserTab.raised:
        return 'My Requests';
      case _UserTab.replied:
        return 'Needs Response';
      case _UserTab.inprogress:
        return 'In Progress';
      case _UserTab.archive:
        return 'Archive';
      case _UserTab.profile:
        return 'Profile';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final repliedState = ref.watch(myRequestsProvider('replied'));
    final repliedCount = repliedState.valueOrNull?.total ?? 0;

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
              if (repliedCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAB387),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      drawer: _UserDrawer(
        currentTab: _tab,
        repliedCount: repliedCount,
        userName: user?.name ?? user?.email ?? '',
        onNavigate: (tab) {
          setState(() => _tab = tab);
          Navigator.pop(context);
        },
      ),
      body: _buildBody(),
      floatingActionButton: _tab != _UserTab.profile
          ? FloatingActionButton.extended(
              onPressed: () => _showNewRequestDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Request',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case _UserTab.raised:
        return const UserRaisedPage();
      case _UserTab.replied:
        return const UserRepliedPage();
      case _UserTab.inprogress:
        return const UserInProgressPage();
      case _UserTab.archive:
        return const UserArchivePage();
      case _UserTab.profile:
        return const ProfilePage();
    }
  }

  void _showNewRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _NewRequestDialog(
        onSuccess: () {
          ref.invalidate(myRequestsProvider('raised'));
        },
      ),
    );
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────

class _UserDrawer extends StatelessWidget {
  final _UserTab currentTab;
  final int repliedCount;
  final String userName;
  final void Function(_UserTab) onNavigate;

  const _UserDrawer({
    required this.currentTab,
    required this.repliedCount,
    required this.userName,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final sections = [
      (
        title: 'MY REQUESTS',
        items: [
          (_UserTab.raised, Icons.fiber_new_rounded, 'Raised', 0),
          (
            _UserTab.replied,
            Icons.reply_rounded,
            'Needs Response',
            repliedCount
          ),
          (_UserTab.inprogress, Icons.pending_rounded, 'In Progress', 0),
          (_UserTab.archive, Icons.task_alt_rounded, 'Archive', 0),
        ],
      ),
      (
        title: 'ACCOUNT',
        items: [
          (_UserTab.profile, Icons.account_circle_rounded, 'Profile', 0),
        ],
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
                        Text('User',
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
                if (badge > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAB387),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$badge',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── New Request Dialog ────────────────────────────────────────────────────────

class _NewRequestDialog extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  const _NewRequestDialog({required this.onSuccess});

  @override
  ConsumerState<_NewRequestDialog> createState() => _NewRequestDialogState();
}

class _NewRequestDialogState extends ConsumerState<_NewRequestDialog> {
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
                // Main type
                mainTypesAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Failed to load types: $e'),
                  data: (mainTypes) => DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Main Type'),
                    value: _selectedMainId,
                    items: mainTypes
                        .map((t) =>
                            DropdownMenuItem(value: t.id, child: Text(t.name)))
                        .toList(),
                    onChanged: (val) {
                      final mt =
                          mainTypesAsync.value?.firstWhere((t) => t.id == val);
                      setState(() {
                        _selectedMainId = val;
                        _selectedMainName = mt?.name;
                        _selectedSubId = null;
                        _selectedSubName = null;
                      });
                    },
                    validator: (v) =>
                        v == null ? 'Please select a main type' : null,
                  ),
                ),
                const SizedBox(height: 12),
                // Sub type
                if (_selectedMainId != null)
                  Consumer(builder: (context, ref, _) {
                    final subAsync =
                        ref.watch(subTypesProvider(_selectedMainId!));
                    return subAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Failed to load sub types: $e'),
                      data: (subTypes) => DropdownButtonFormField<int>(
                        decoration:
                            const InputDecoration(labelText: 'Sub Type'),
                        value: _selectedSubId,
                        items: subTypes
                            .map((t) => DropdownMenuItem(
                                value: t.id, child: Text(t.name)))
                            .toList(),
                        onChanged: (val) {
                          final st =
                              subAsync.value?.firstWhere((t) => t.id == val);
                          setState(() {
                            _selectedSubId = val;
                            _selectedSubName = st?.name;
                          });
                        },
                        validator: (v) =>
                            v == null ? 'Please select a sub type' : null,
                      ),
                    );
                  }),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _roomController,
                  decoration: const InputDecoration(labelText: 'Room No'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Room number is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone No'),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    if (v.trim().length != 10) {
                      return 'Phone number must be 10 digits';
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMainName == null || _selectedSubName == null) return;

    setState(() => _isSubmitting = true);
    final notifier = ref.read(myRequestsProvider('raised').notifier);
    final success = await notifier.createRequest(
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

// Expose providers needed by _NewRequestDialog
