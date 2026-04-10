import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/domain/entities/track_entity.dart';

class AdminRequestDetailPage extends ConsumerStatefulWidget {
  final String requestId;

  const AdminRequestDetailPage({super.key, required this.requestId});

  @override
  ConsumerState<AdminRequestDetailPage> createState() =>
      _AdminRequestDetailPageState();
}

class _AdminRequestDetailPageState
    extends ConsumerState<AdminRequestDetailPage> {
  final _networkClient = NetworkClient();
  Request? _request;
  List<Track> _tracks = [];
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
          await _networkClient.get('/requests/${widget.requestId}/comments');

      setState(() {
        _request = Request.fromJson(requestResponse.data);
        _tracks = (tracksResponse.data as List)
            .map((json) => Track.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
                    // Request Details Card
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Status: ${_request!.statusDisplayText}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _getStatusChip(_request!.status),
                              ],
                            ),
                            const Divider(height: 24),
                            const Text(
                              'Description:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(_request!.description),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Created: ${_formatDate(_request!.createdAt)}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'Updated: ${_formatDate(_request!.updatedAt)}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _request!.isActive == 'true'
                                        ? Colors.green
                                        : Colors.grey,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _request!.isActive == 'true'
                                        ? 'ACTIVE'
                                        : 'INACTIVE',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Timeline Section Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Text(
                            'Timeline',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_tracks.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Timeline List
                    Expanded(
                      child: _tracks.isEmpty
                          ? const Center(
                              child: Text('No activity yet'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _tracks.length,
                              itemBuilder: (context, index) {
                                final track = _tracks[index];
                                return _buildTrackItem(
                                    track, index == _tracks.length - 1);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTrackItem(Track track, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getActionTypeColor(track.actionType),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getActionTypeIcon(track.actionType),
                color: Colors.white,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Track content
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          track.actionDisplayText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(track.performedByRole),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          track.performedByRole,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(track.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  if (track.comment != null && track.comment!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        track.comment!,
                        style: const TextStyle(fontSize: 13),
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

  Widget _getStatusChip(String status) {
    Color color;
    switch (status) {
      case 'RAISED':
        color = Colors.blue;
        break;
      case 'REPLIED':
        color = Colors.orange;
        break;
      case 'ASSIGNED':
        color = Colors.purple;
        break;
      case 'IN_PROGRESS':
        color = Colors.amber;
        break;
      case 'COMPLETED':
        color = Colors.green;
        break;
      case 'REJECTED':
        color = Colors.red;
        break;
      case 'REASSIGN_REQUESTED':
        color = Colors.pink;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  Color _getActionTypeColor(String actionType) {
    switch (actionType) {
      case 'RAISED':
        return Colors.blue;
      case 'REPLIED':
        return Colors.orange;
      case 'REJECTED':
        return Colors.red;
      case 'ASSIGNED':
        return Colors.purple;
      case 'IN_PROGRESS':
        return Colors.amber;
      case 'COMPLETED':
        return Colors.green;
      case 'REASSIGN_REQUESTED':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionTypeIcon(String actionType) {
    switch (actionType) {
      case 'RAISED':
        return Icons.add_circle;
      case 'REPLIED':
        return Icons.chat_bubble;
      case 'REJECTED':
        return Icons.cancel;
      case 'ASSIGNED':
        return Icons.person_add;
      case 'IN_PROGRESS':
        return Icons.work;
      case 'COMPLETED':
        return Icons.check_circle;
      case 'REASSIGN_REQUESTED':
        return Icons.swap_horiz;
      case 'STORE_REQUEST_CREATED':
      case 'STORE_REQUEST_APPROVED':
      case 'STORE_REQUEST_REJECTED':
      case 'STORE_REQUEST_FULFILLED':
        return Icons.inventory;
      default:
        return Icons.circle;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return Colors.red;
      case 'STAFF':
        return Colors.blue;
      case 'STORE':
        return Colors.green;
      case 'USER':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
