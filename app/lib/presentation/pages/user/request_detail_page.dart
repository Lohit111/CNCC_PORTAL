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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequestDetails();
  }

  Future<void> _loadRequestDetails() async {
    setState(() => _isLoading = true);
    try {
      final requestResponse =
          await _networkClient.get('/requests/${widget.requestId}');
      final tracksResponse =
          await _networkClient.get('/requests/${widget.requestId}/timeline');

      setState(() {
        _request = Request.fromJson(requestResponse.data);
        _tracks = (tracksResponse.data as List)
            .map((json) => Track.fromJson(json))
            .toList();
        _isLoading = false;
      });
      await _fetchPerformerEmails();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _fetchPerformerEmails() async {
    final ids = _tracks.map((t) => t.performedBy).toSet().toList();
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRequestDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _request == null
              ? const Center(child: Text('Request not found'))
              : Column(
                  children: [
                    _buildHeaderCard(cs),
                    _buildTimelineHeader(cs),
                    Expanded(child: _buildTimeline(cs)),
                    if (_request!.status == 'REPLIED') _buildRespondBar(cs),
                  ],
                ),
    );
  }

  Widget _buildHeaderCard(ColorScheme cs) {
    final statusColor = _statusColor(_request!.status);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(_request!.status),
                        size: 13, color: statusColor),
                    const SizedBox(width: 5),
                    Text(
                      _request!.statusDisplayText,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(_request!.updatedAt),
                style: TextStyle(
                    fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _request!.description,
            style: TextStyle(fontSize: 15, color: cs.onSurface, height: 1.5),
          ),
          const SizedBox(height: 10),
          Divider(color: cs.onSurface.withValues(alpha: 0.06)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 12, color: cs.onSurface.withValues(alpha: 0.35)),
              const SizedBox(width: 5),
              Text(
                'Created ${_formatDate(_request!.createdAt)}',
                style: TextStyle(
                    fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          Text(
            'Timeline',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
          ),
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
                  fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(ColorScheme cs) {
    if (_tracks.isEmpty) {
      return Center(
        child: Text('No activity yet',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _tracks.length,
      itemBuilder: (context, index) =>
          _buildTrackItem(_tracks[index], index == _tracks.length - 1, cs),
    );
  }

  Widget _buildTrackItem(Track track, bool isLast, ColorScheme cs) {
    final actionColor = _actionColor(track.actionType);
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
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
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
                  const SizedBox(height: 4),
                  Text(
                    _performerEmails[track.performedBy] ?? 'Unknown',
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                  Text(
                    _formatDate(track.createdAt),
                    style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurface.withValues(alpha: 0.35)),
                  ),
                  if (track.comment != null && track.comment!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        track.comment!,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.8),
                            height: 1.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

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
          _loadRequestDetails();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending response: $e')),
          );
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

  // ── helpers ──────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
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

  IconData _statusIcon(String status) {
    switch (status) {
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

  Color _actionColor(String actionType) {
    switch (actionType) {
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

  IconData _actionIcon(String actionType) {
    switch (actionType) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
