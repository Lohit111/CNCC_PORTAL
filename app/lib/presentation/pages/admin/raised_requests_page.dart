import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/domain/entities/type_entity.dart';

class RaisedRequestsPage extends StatefulWidget {
  const RaisedRequestsPage({super.key});

  @override
  State<RaisedRequestsPage> createState() => _RaisedRequestsPageState();
}

class _RaisedRequestsPageState extends State<RaisedRequestsPage> {
  final _networkClient = NetworkClient();
  List<Request> _requests = [];
  final Map<int, String> _mainTypeNames = {};
  final Map<int, String> _subTypeNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await _networkClient.get('/requests/');
      final data = response.data;
      final requests = (data['items'] as List)
          .map((json) => Request.fromJson(json))
          .where((req) => req.status == 'RAISED' && req.isActive == 'true')
          .toList();
      await _loadTypeNames(requests);
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTypeNames(List<Request> requests) async {
    try {
      final mainRes = await _networkClient.get('/types/main');
      for (final j in (mainRes.data as List)) {
        final mt = MainType.fromJson(j);
        _mainTypeNames[mt.id] = mt.name;
      }
      for (final mainId in requests.map((r) => r.mainTypeId).toSet()) {
        final subRes = await _networkClient.get('/types/main/$mainId/sub');
        for (final j in (subRes.data as List)) {
          final st = SubType.fromJson(j);
          _subTypeNames[st.id] = st.name;
        }
      }
    } catch (_) {}
  }

  String _mainTypeName(int id) => _mainTypeNames[id] ?? 'Type $id';
  String _subTypeName(int id) => _subTypeNames[id] ?? 'Sub $id';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raised'),
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
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded,
                size: 56, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 14),
            Text('No raised requests',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return _RaisedCard(
          request: request,
          mainTypeName: _mainTypeName(request.mainTypeId),
          subTypeName: _subTypeName(request.subTypeId),
          onRefresh: _loadRequests,
        );
      },
    );
  }
}

class _RaisedCard extends StatefulWidget {
  final Request request;
  final String mainTypeName;
  final String subTypeName;
  final VoidCallback onRefresh;

  const _RaisedCard({
    required this.request,
    required this.mainTypeName,
    required this.subTypeName,
    required this.onRefresh,
  });

  @override
  State<_RaisedCard> createState() => _RaisedCardState();
}

class _RaisedCardState extends State<_RaisedCard> {
  final _networkClient = NetworkClient();
  String? _createdByEmail;
  String? _createdByRole;
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
        _createdByRole = lastTrack['performed_by_role'] as String?;
        final performedById = lastTrack['performed_by'] as String?;
        if (performedById != null) {
          try {
            final emailRes =
                await _networkClient.get('/users/emails?ids=$performedById');
            if (emailRes.data is Map) {
              _createdByEmail =
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
    const accent = Color(0xFF89B4FA);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    widget.request.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14, color: cs.onSurface, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  // Info rows
                  _InfoRow(label: 'Main Type', value: widget.mainTypeName),
                  const SizedBox(height: 3),
                  _InfoRow(label: 'Sub Type', value: widget.subTypeName),
                  const SizedBox(height: 3),
                  _InfoRow(
                      label: 'Updated at',
                      value: _formatDate(widget.request.updatedAt)),
                  if (_extraLoading) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: cs.onSurface.withValues(alpha: 0.3)),
                    ),
                  ] else if (_createdByEmail != null ||
                      _createdByRole != null) ...[
                    const SizedBox(height: 3),
                    _InfoRow(
                      label: 'Created by',
                      value: [
                        if (_createdByRole != null) _createdByRole!,
                        if (_createdByEmail != null) _createdByEmail!,
                      ].join(' · '),
                    ),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showActionDialog(context, widget.request, 'REPLY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFAB387),
                        foregroundColor: Colors.black87,
                      ),
                      icon: const Icon(Icons.reply_rounded, size: 16),
                      label:
                          const Text('Reply', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showActionDialog(context, widget.request, 'REJECT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF38BA8),
                        foregroundColor: Colors.black87,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label:
                          const Text('Reject', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showAssignDialog(context, widget.request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA6E3A1),
                        foregroundColor: Colors.black87,
                      ),
                      icon: const Icon(Icons.person_add_rounded, size: 16),
                      label:
                          const Text('Assign', style: TextStyle(fontSize: 13)),
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

  Future<void> _showActionDialog(
      BuildContext context, Request request, String action) async {
    final commentController = TextEditingController();
    final isReply = action == 'REPLY';
    final color = isReply ? const Color(0xFFFAB387) : const Color(0xFFF38BA8);
    final newStatus = isReply ? 'REPLIED' : 'REJECTED';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isReply ? 'Reply to Request' : 'Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: isReply ? 'Your Reply' : 'Rejection Reason',
                hintText: isReply
                    ? 'Ask for more information...'
                    : 'Explain why this is rejected...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: color, foregroundColor: Colors.black87),
            child: Text(isReply ? 'Send Reply' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && commentController.text.isNotEmpty) {
      try {
        final networkClient = NetworkClient();
        await networkClient.put('/requests/${request.id}', data: {
          'status': newStatus,
          'comment': commentController.text,
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(isReply ? 'Reply sent' : 'Request rejected')),
          );
          widget.onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _showAssignDialog(BuildContext context, Request request) async {
    try {
      final networkClient = NetworkClient();
      final usersResponse = await networkClient.get('/users/');
      final rolesResponse = await networkClient.get('/roles/');

      final users = usersResponse.data['items'] as List;
      final roles = rolesResponse.data['items'] as List;

      final staffList = users.where((user) {
        final role = roles.firstWhere(
          (r) => r['email'] == user['email'],
          orElse: () => null,
        );
        return role != null && role['role'] == 'STAFF';
      }).toList();

      if (!context.mounted) return;

      final Set<String> selectedIds = {};

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Assign to Staff'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Select one or more staff members:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: staffList.isEmpty
                        ? const Text('No staff members available.')
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: staffList.length,
                            itemBuilder: (context, index) {
                              final staff = staffList[index];
                              final id = staff['id'] as String;
                              return CheckboxListTile(
                                dense: true,
                                title: Text(staff['email'] as String),
                                value: selectedIds.contains(id),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      selectedIds.add(id);
                                    } else {
                                      selectedIds.remove(id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  if (selectedIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${selectedIds.length} selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                onPressed: selectedIds.isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
                child: const Text('Assign'),
              ),
            ],
          ),
        ),
      );

      if (confirmed == true && selectedIds.isNotEmpty) {
        await networkClient.post('/assignments/bulk', data: {
          'request_id': request.id,
          'staff_ids': selectedIds.toList(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${selectedIds.length} staff assigned')),
          );
          widget.onRefresh();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year} '
      '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TypeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
