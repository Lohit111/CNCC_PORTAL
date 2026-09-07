import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cncc_portal/presentation/providers/admin_provider.dart';

class AdminNotificationsPage extends ConsumerStatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  ConsumerState<AdminNotificationsPage> createState() =>
      _AdminNotificationsPageState();
}

class _AdminNotificationsPageState
    extends ConsumerState<AdminNotificationsPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  _NotificationTarget _target = _NotificationTarget.broadcast;
  String _role = 'STAFF';
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      _showMessage('Title and body are required.');
      return;
    }

    setState(() => _isSending = true);

    final notifier = ref.read(adminProvider('raised').notifier);

    bool success;

    switch (_target) {
      case _NotificationTarget.broadcast:
        success = await notifier.sendBroadcast(title, body);
        break;

      case _NotificationTarget.role:
        success = await notifier.sendToRole(
          _role,
          title,
          body,
        );
        break;
    }

    if (!mounted) return;

    setState(() => _isSending = false);

    if (success) {
      _showMessage('Notification sent successfully.');

      _titleController.clear();
      _bodyController.clear();
    } else {
      _showMessage('Failed to send notification.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_rounded,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Send Notification',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Target
                  Text(
                    'Recipient',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),

                  const SizedBox(height: 8),

                  Column(
                    children: [
                      _NotificationTargetTile(
                        icon: Icons.campaign_rounded,
                        title: 'Everyone',
                        subtitle: 'Send to all active users',
                        selected: _target == _NotificationTarget.broadcast,
                        enabled: !_isSending,
                        onTap: () {
                          setState(
                              () => _target = _NotificationTarget.broadcast);
                        },
                      ),
                      const SizedBox(height: 8),
                      _NotificationTargetTile(
                        icon: Icons.groups_rounded,
                        title: 'Role',
                        subtitle: 'Send to users with a specific role',
                        selected: _target == _NotificationTarget.role,
                        enabled: !_isSending,
                        onTap: () {
                          setState(() => _target = _NotificationTarget.role);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Role selector
                  if (_target == _NotificationTarget.role) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.outlineVariant,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Role',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _RoleChip(
                                  label: 'Admin',
                                  value: 'ADMIN',
                                  icon: Icons.admin_panel_settings_rounded,
                                  selected: _role == 'ADMIN',
                                  enabled: !_isSending,
                                  onTap: () => setState(() => _role = 'ADMIN'),
                                ),
                                _RoleChip(
                                  label: 'Staff',
                                  value: 'STAFF',
                                  icon: Icons.badge_rounded,
                                  selected: _role == 'STAFF',
                                  enabled: !_isSending,
                                  onTap: () => setState(() => _role = 'STAFF'),
                                ),
                                _RoleChip(
                                  label: 'Store',
                                  value: 'STORE',
                                  icon: Icons.store_rounded,
                                  selected: _role == 'STORE',
                                  enabled: !_isSending,
                                  onTap: () => setState(() => _role = 'STORE'),
                                ),
                                _RoleChip(
                                  label: 'User',
                                  value: 'USER',
                                  icon: Icons.person_rounded,
                                  selected: _role == 'USER',
                                  enabled: !_isSending,
                                  onTap: () => setState(() => _role = 'USER'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Title
                  TextField(
                    controller: _titleController,
                    enabled: !_isSending,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Notification title',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Body
                  TextField(
                    controller: _bodyController,
                    enabled: !_isSending,
                    maxLength: 500,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      hintText: 'Notification message',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Warning
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.errorContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: cs.onErrorContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _targetDescription,
                            style: TextStyle(
                              color: cs.onErrorContainer,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSending ? null : _sendNotification,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _isSending ? 'Sending...' : 'Send Notification',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  

  String get _targetDescription {
    switch (_target) {
      case _NotificationTarget.broadcast:
        return 'This notification will be sent to every active user with a registered device.';

      case _NotificationTarget.role:
        return 'This notification will be sent to every active user with the selected role.';
    }
  }
}

class _NotificationTargetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _NotificationTargetTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer
              : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? cs.primary
                : cs.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: selected
                  ? cs.primary
                  : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? cs.primary
                    : cs.onSurface,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_rounded,
                size: 18,
                color: cs.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _NotificationTarget {
  broadcast,
  role,
}
