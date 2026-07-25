import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/domain/entities/track_entity.dart';

class RequestDetailPage extends ConsumerStatefulWidget {
  final String requestId;

  const RequestDetailPage({super.key, required this.requestId});

  @override
  ConsumerState<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends ConsumerState<RequestDetailPage> {
  final _networkClient = NetworkClient();

  Request? _request;
  List<Track> _tracks = [];
  final Map<String, String> _performerEmails = {};

  String _mainTypeName = '—';
  String _subTypeName = '—';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _networkClient.get('/requests/${widget.requestId}'),
        _networkClient.get('/requests/${widget.requestId}/timeline'),
        _networkClient.get('/types/main'),
      ]);

      final request = Request.fromJson(results[0].data);
      final tracks = (results[1].data as List)
          .map((json) => Track.fromJson(json))
          .toList();
      final mainTypes = results[2].data as List;

      // Resolve main type name
      final mainTypeMap = <int, String>{
        for (final t in mainTypes) (t['id'] as int): t['name'] as String,
      };
      String mainTypeName = mainTypeMap[request.mainTypeId] ?? '—';
      String subTypeName = '—';
      try {
        final subRes =
            await _networkClient.get('/types/main/${request.mainTypeId}/sub');
        final subMap = <int, String>{
          for (final s in subRes.data as List)
            (s['id'] as int): s['name'] as String,
        };
        subTypeName = subMap[request.subTypeId] ?? '—';
      } catch (_) {}

      setState(() {
        _request = request;
        _tracks = tracks;
        _mainTypeName = mainTypeName;
        _subTypeName = subTypeName;
        _isLoading = false;
      });

      await _fetchPerformerEmails(tracks);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _fetchPerformerEmails(List<Track> tracks) async {
    final ids = tracks.map((t) => t.performedBy).toSet().toList();
    if (ids.isEmpty) return;
    try {
      final queryParams = ids.map((id) => 'ids=$id').join('&');
      final res = await _networkClient.get('/users/emails?$queryParams');
      if (res.data is Map) {
        (res.data as Map).forEach((k, v) {
          _performerEmails[k.toString()] = v.toString();
        });
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _request == null
              ? const Center(child: Text('Request not found'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        children: [
                          _buildHeaderCard(cs),
                          const SizedBox(height: 16),
                          _buildTimelineSection(cs),
                        ],
                      ),
                    ),
                    if (_request!.status == 'REPLIED') _buildRespondBar(cs),
                  ],
                ),
    );
  }

  // ── Header card ────────────────────────────────────────────────────────────
  // Only: description, main type, sub type, created at

  Widget _buildHeaderCard(ColorScheme cs) {
    final req = _request!;
    final statusColor = _statusColor(req.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_statusIcon(req.status), size: 13, color: statusColor),
                const SizedBox(width: 5),
                Text(
                  req.statusDisplayText,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            req.description,
            style: TextStyle(fontSize: 15, color: cs.onSurface, height: 1.5),
          ),
          const SizedBox(height: 12),
          Divider(color: cs.onSurface.withValues(alpha: 0.06)),
          const SizedBox(height: 8),

          _InfoRow(label: 'Main Type', value: _mainTypeName),
          const SizedBox(height: 4),
          _InfoRow(label: 'Sub Type', value: _subTypeName),
          const SizedBox(height: 4),
          _InfoRow(label: 'Created', value: _formatDate(req.createdAt)),
        ],
      ),
    );
  }

  // ── Timeline ───────────────────────────────────────────────────────────────

  Widget _buildTimelineSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Timeline',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_tracks.length}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_tracks.isEmpty)
          Text('No activity yet',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)))
        else
          ...List.generate(
            _tracks.length,
            (i) => _buildTrackTile(_tracks[i], i == _tracks.length - 1, cs),
          ),
      ],
    );
  }

  Widget _buildTrackTile(Track track, bool isLast, ColorScheme cs) {
    final actionColor = _actionColor(track.actionType);
    final performerLabel = _performerLabel(track.actionType);
    final performerEmail = _performerEmails[track.performedBy] ?? '…';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Connector column
        SizedBox(
          width: 44,
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_actionIcon(track.actionType),
                    color: actionColor, size: 17),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 52,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        actionColor.withValues(alpha: 0.4),
                        actionColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: action label + role badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        track.actionDisplayText,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: cs.onSurface),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _roleColor(track.performedByRole)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        track.performedByRole,
                        style: TextStyle(
                            color: _roleColor(track.performedByRole),
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Performer label + email
                _InfoRow(label: performerLabel, value: performerEmail),
                const SizedBox(height: 3),
                // Timestamp
                _InfoRow(
                    label: 'Updated at', value: _formatDate(track.createdAt)),

                // Comment
                if (track.comment != null &&
                    track.comment!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _CommentBox(comment: track.comment!.trim()),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Respond bar ────────────────────────────────────────────────────────────

  Widget _buildRespondBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
            top: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showRespondDialog(_request!),
          icon: const Icon(Icons.reply_rounded, size: 18),
          label: const Text('Respond to Admin',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: const Color(0xFFFAB387),
            foregroundColor: Colors.black87,
          ),
        ),
      ),
    );
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
                decoration:
                    const InputDecoration(labelText: 'Updated Description'),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Additional Comment',
                  hintText: 'Explain what you updated…',
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
          _load();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        descriptionController.dispose();
        commentController.dispose();
      }
    } else {
      descriptionController.dispose();
      commentController.dispose();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns a contextual "performed by" label based on action type.
  String _performerLabel(String actionType) {
    switch (actionType) {
      case 'RAISED':
        return 'Created by';
      case 'REPLIED':
        return 'Replied by';
      case 'ASSIGNED':
        return 'Assigned by';
      case 'IN_PROGRESS':
        return 'Started by';
      case 'REASSIGN_REQUESTED':
        return 'Requested by';
      case 'COMPLETED':
      case 'REJECTED':
        return 'Closed by';
      default:
        return 'Performed by';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'RAISED':
        return const Color(0xFF89B4FA);
      case 'REPLIED':
        return const Color(0xFFFAB387);
      case 'ASSIGNED':
        return const Color(0xFFCBA6F7);
      case 'IN_PROGRESS':
        return const Color(0xFFF9E2AF);
      case 'COMPLETED':
        return const Color(0xFFA6E3A1);
      case 'REJECTED':
        return const Color(0xFFF38BA8);
      case 'REASSIGN_REQUESTED':
        return const Color(0xFFEBA0AC);
      default:
        return const Color(0xFF6C7086);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'RAISED':
        return Icons.fiber_new_rounded;
      case 'REPLIED':
        return Icons.reply_rounded;
      case 'ASSIGNED':
        return Icons.assignment_ind_rounded;
      case 'IN_PROGRESS':
        return Icons.pending_rounded;
      case 'COMPLETED':
        return Icons.check_circle_rounded;
      case 'REJECTED':
        return Icons.cancel_rounded;
      case 'REASSIGN_REQUESTED':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _actionColor(String s) {
    switch (s) {
      case 'RAISED':
        return const Color(0xFF89B4FA);
      case 'REPLIED':
        return const Color(0xFFFAB387);
      case 'REJECTED':
        return const Color(0xFFF38BA8);
      case 'ASSIGNED':
        return const Color(0xFFCBA6F7);
      case 'IN_PROGRESS':
        return const Color(0xFFF9E2AF);
      case 'COMPLETED':
        return const Color(0xFFA6E3A1);
      case 'REASSIGN_REQUESTED':
        return const Color(0xFFEBA0AC);
      default:
        return const Color(0xFF6C7086);
    }
  }

  IconData _actionIcon(String s) {
    switch (s) {
      case 'RAISED':
        return Icons.add_circle_rounded;
      case 'REPLIED':
        return Icons.chat_bubble_rounded;
      case 'REJECTED':
        return Icons.cancel_rounded;
      case 'ASSIGNED':
        return Icons.person_add_rounded;
      case 'IN_PROGRESS':
        return Icons.work_rounded;
      case 'COMPLETED':
        return Icons.check_circle_rounded;
      case 'REASSIGN_REQUESTED':
        return Icons.swap_horiz_rounded;
      case 'STORE_REQUEST_CREATED':
      case 'STORE_REQUEST_APPROVED':
      case 'STORE_REQUEST_REJECTED':
      case 'STORE_REQUEST_FULFILLED':
        return Icons.inventory_2_rounded;
      default:
        return Icons.circle;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return const Color(0xFFF38BA8);
      case 'STAFF':
        return const Color(0xFF89B4FA);
      case 'STORE':
        return const Color(0xFFA6E3A1);
      case 'USER':
        return const Color(0xFFFAB387);
      default:
        return const Color(0xFF6C7086);
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year} '
      '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

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
          width: 90,
          child: Text(
            '$label:',
            style: TextStyle(
                fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withValues(alpha: 0.8)),
          ),
        ),
      ],
    );
  }
}

class _CommentBox extends StatelessWidget {
  final String comment;

  const _CommentBox({required this.comment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        comment,
        style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.8),
            height: 1.4),
      ),
    );
  }
}
