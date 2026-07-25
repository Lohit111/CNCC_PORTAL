import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/domain/entities/track_entity.dart';

class RepliedRequestsUserPage extends StatefulWidget {
  const RepliedRequestsUserPage({super.key});

  @override
  State<RepliedRequestsUserPage> createState() =>
      _RepliedRequestsUserPageState();
}

class _RepliedRequestsUserPageState extends State<RepliedRequestsUserPage> {
  final _networkClient = NetworkClient();
  List<Request> _requests = [];
  bool _isLoading = true;

  Map<int, String> _mainTypeNames = {};
  Map<int, String> _subTypeNames = {};

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _networkClient.get('/users/requests'),
        _networkClient.get('/types/main'),
      ]);

      final requestData = results[0].data;
      final mainTypes = results[1].data as List;

      final mainTypeNames = <int, String>{
        for (final t in mainTypes) (t['id'] as int): t['name'] as String,
      };

      final filtered = (requestData['items'] as List)
          .map((json) => Request.fromJson(json))
          .where((req) => req.status == 'REPLIED' && req.isActive == 'true')
          .toList();

      final subTypeNames = <int, String>{};
      final mainTypeIds = filtered.map((r) => r.mainTypeId).toSet().toList();
      await Future.wait(mainTypeIds.map((mid) async {
        try {
          final res = await _networkClient.get('/types/main/$mid/sub');
          for (final s in res.data as List) {
            subTypeNames[s['id'] as int] = s['name'] as String;
          }
        } catch (_) {}
      }));

      setState(() {
        _requests = filtered;
        _mainTypeNames = mainTypeNames;
        _subTypeNames = subTypeNames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Needs Response'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_read_rounded,
                size: 56,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2)),
            const SizedBox(height: 14),
            Text(
              'All caught up!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No requests need your response',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return _RepliedCard(
          request: request,
          mainTypeName: _mainTypeNames[request.mainTypeId] ?? '—',
          subTypeName: _subTypeNames[request.subTypeId] ?? '—',
          onViewConversation: () => _viewConversation(request),
          onRespond: () => _showRespondDialog(request),
        );
      },
    );
  }

  Future<void> _viewConversation(Request request) async {
    try {
      final response =
          await _networkClient.get('/requests/${request.id}/timeline');
      final tracks =
          (response.data as List).map((json) => Track.fromJson(json)).toList();

      final Map<String, String> performerEmails = {};
      final ids = tracks.map((t) => t.performedBy).toSet().toList();
      if (ids.isNotEmpty) {
        try {
          final queryParams = ids.map((id) => 'ids=$id').join('&');
          final res = await _networkClient.get('/users/emails?$queryParams');
          if (res.data is Map) {
            (res.data as Map).forEach((k, v) {
              performerEmails[k.toString()] = v.toString();
            });
          }
        } catch (_) {}
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            title: const Text('Conversation'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  final isAdmin = track.performedByRole == 'ADMIN';
                  final email = performerEmails[track.performedBy] ?? 'Unknown';
                  final bubbleColor = isAdmin
                      ? const Color(0xFFFAB387).withValues(alpha: 0.12)
                      : const Color(0xFF89B4FA).withValues(alpha: 0.12);
                  final iconColor = isAdmin
                      ? const Color(0xFFFAB387)
                      : const Color(0xFF89B4FA);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: iconColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isAdmin
                                  ? Icons.admin_panel_settings_rounded
                                  : Icons.person_rounded,
                              color: iconColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              track.performedByRole,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: iconColor),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                email,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withValues(alpha: 0.5)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          track.actionDisplayText,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface),
                        ),
                        if (track.comment != null &&
                            track.comment!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            track.comment!,
                            style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: cs.onSurface.withValues(alpha: 0.7)),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversation: $e')),
        );
      }
    }
  }

  Future<void> _showRespondDialog(Request request) async {
    final descriptionController =
        TextEditingController(text: request.description);
    final commentController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Admin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update your request with more information:',
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Updated Description',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Additional Comment',
                  hintText: 'Explain what you updated...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Response'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _networkClient.put('/requests/${request.id}', data: {
          'description': descriptionController.text,
          'status': 'RAISED',
          'comment': commentController.text,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Response sent successfully')),
          );
          _loadRequests();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending response: $e')),
          );
        }
      }
    }
  }
}

class _RepliedCard extends StatefulWidget {
  final Request request;
  final String mainTypeName;
  final String subTypeName;
  final VoidCallback onViewConversation;
  final VoidCallback onRespond;

  const _RepliedCard({
    required this.request,
    required this.mainTypeName,
    required this.subTypeName,
    required this.onViewConversation,
    required this.onRespond,
  });

  @override
  State<_RepliedCard> createState() => _RepliedCardState();
}

class _RepliedCardState extends State<_RepliedCard> {
  final _networkClient = NetworkClient();
  String? _repliedByEmail;
  String? _lastTrackComment;
  bool _extraLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExtra();
  }

  Future<void> _loadExtra() async {
    try {
      final trackRes =
          await _networkClient.get('/requests/${widget.request.id}/timeline');
      final tracks = trackRes.data as List;
      if (tracks.isNotEmpty) {
        final lastTrack = tracks.last;
        final performedById = lastTrack['performed_by'] as String?;
        _lastTrackComment = lastTrack['comment'] as String?;
        if (performedById != null) {
          try {
            final emailRes =
                await _networkClient.get('/users/emails?ids=$performedById');
            if (emailRes.data is Map) {
              _repliedByEmail =
                  (emailRes.data as Map)[performedById]?.toString();
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _extraLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const accent = Color(0xFFFAB387);
    final request = widget.request;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.reply_rounded,
                        color: accent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      request.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Info rows
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _InfoRow(label: 'Main Type', value: widget.mainTypeName),
                  const SizedBox(height: 2),
                  _InfoRow(label: 'Sub Type', value: widget.subTypeName),
                  const SizedBox(height: 2),
                  _InfoRow(
                      label: 'Updated',
                      value: _formatDateTime(request.updatedAt)),
                  const SizedBox(height: 2),
                  _InfoRow(
                      label: 'Created',
                      value: _formatDateTime(request.createdAt)),
                  if (_extraLoading) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: cs.onSurface.withValues(alpha: 0.3)),
                    ),
                  ] else if (_repliedByEmail != null) ...[
                    const SizedBox(height: 2),
                    _InfoRow(label: 'Replied by', value: _repliedByEmail!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Admin comment / action-required badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.reply_rounded, size: 13, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Admin replied — ${(_lastTrackComment != null && _lastTrackComment!.trim().isNotEmpty) ? _lastTrackComment!.trim() : 'your response needed'}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: accent,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onViewConversation,
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 16),
                      label: const Text('View Thread',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onRespond,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.black87),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label:
                          const Text('Respond', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ),
      ],
    );
  }
}
