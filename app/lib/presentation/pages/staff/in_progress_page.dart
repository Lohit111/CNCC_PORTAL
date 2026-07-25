import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/core/utils/error_handler.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/domain/entities/type_entity.dart';
import 'package:cncc_portal/presentation/providers/auth_provider.dart';

class InProgressPage extends ConsumerStatefulWidget {
  const InProgressPage({super.key});

  @override
  ConsumerState<InProgressPage> createState() => _InProgressPageState();
}

class _InProgressPageState extends ConsumerState<InProgressPage> {
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
      final user = ref.read(authProvider).user;
      if (user == null) return;

      final assignmentsResponse = await _networkClient.get(
        '/assignments/staff/${user.id}',
        queryParameters: {'active_only': true},
      );
      final assignments = assignmentsResponse.data as List;

      final requestsResponse = await _networkClient.get('/requests/');
      final allRequests = (requestsResponse.data['items'] as List)
          .map((json) => Request.fromJson(json))
          .toList();

      final assignedRequestIds =
          assignments.map((a) => a['request_id']).toSet();
      final filtered = allRequests
          .where((req) =>
              assignedRequestIds.contains(req.id) &&
              req.status == 'IN_PROGRESS' &&
              req.isActive == 'true')
          .toList();
      await _loadTypeNames(filtered);
      setState(() {
        _requests = filtered;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In Progress'),
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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded,
                size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No requests in progress',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            Text('Start working on assigned requests',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.35))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return _InProgressCard(
          request: request,
          mainTypeName: _mainTypeNames[request.mainTypeId] ?? '—',
          subTypeName: _subTypeNames[request.subTypeId] ?? '—',
          onViewStaff: () => _viewAssignedStaff(request),
          onRequestEquipment: () => _showCreateStoreRequestDialog(request),
          onMarkComplete: () => _showCompleteDialog(request),
        );
      },
    );
  }

  Future<void> _viewAssignedStaff(Request request) async {
    try {
      final response =
          await _networkClient.get('/assignments/request/${request.id}');
      final activeAssignments =
          (response.data as List).where((a) => a['is_active'] == true).toList();

      final Map<String, String> staffEmails = {};
      final ids = activeAssignments
          .map((a) => a['staff_id'] as String)
          .toSet()
          .toList();
      if (ids.isNotEmpty) {
        try {
          final queryParams = ids.map((id) => 'ids=$id').join('&');
          final res = await _networkClient.get('/users/emails?$queryParams');
          if (res.data is Map) {
            (res.data as Map)
                .forEach((k, v) => staffEmails[k.toString()] = v.toString());
          }
        } catch (_) {}
      }

      if (!mounted) return;

      final cs = Theme.of(context).colorScheme;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Assigned Staff'),
          content: activeAssignments.isEmpty
              ? Text('No active staff assigned.',
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)))
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: activeAssignments.length,
                    itemBuilder: (context, index) {
                      final staffId =
                          activeAssignments[index]['staff_id'] as String;
                      return ListTile(
                        leading: const Icon(Icons.person_rounded,
                            color: Color(0xFFA6E3A1)),
                        title: Text(staffEmails[staffId] ?? 'Unknown'),
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
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading staff: $e')),
        );
      }
    }
  }

  Future<void> _showCreateStoreRequestDialog(Request request) async {
    final descriptionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Request Equipment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For: ${request.description.length > 40 ? '${request.description.substring(0, 40)}...' : request.description}',
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Equipment Description (required)',
                  hintText: 'List the items you need...',
                ),
                maxLines: 4,
                onChanged: (value) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: descriptionController.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Create Request'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _networkClient.post('/store-requests/', data: {
          'parent_request_id': request.id,
          'description': descriptionController.text,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Store request created')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _showCompleteDialog(Request request) async {
    final commentController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Complete'),
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
                      .withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Completion Notes',
                hintText: 'What did you do to resolve this?',
              ),
              maxLines: 4,
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
              backgroundColor: const Color(0xFFA6E3A1),
              foregroundColor: Colors.black87,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _networkClient.put('/requests/${request.id}', data: {
          'status': 'COMPLETED',
          'comment': commentController.text.isEmpty
              ? 'Request completed'
              : commentController.text,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request marked as complete')),
          );
          _loadRequests();
        }
      } catch (e) {
        if (mounted) {
          final msg = ErrorHandler.handle(e).message;
          List<dynamic>? pendingStoreRequests;
          if (e is DioException &&
              e.response?.data is Map &&
              e.response!.data['detail'] is Map) {
            final detail = e.response!.data['detail'] as Map;
            pendingStoreRequests = detail['pending_store_requests'] as List?;
          }

          final cs = Theme.of(context).colorScheme;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFF9E2AF)),
                  SizedBox(width: 8),
                  Text('Cannot Complete'),
                ],
              ),
              content: pendingStoreRequests != null &&
                      pendingStoreRequests.isNotEmpty
                  ? SizedBox(
                      width: double.maxFinite,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pendingStoreRequests.length} store request(s) still pending:',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 300),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: pendingStoreRequests.length,
                              itemBuilder: (context, index) {
                                final sr = pendingStoreRequests![index]
                                    as Map<String, dynamic>;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: cs.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: cs.onSurface
                                            .withValues(alpha: 0.08)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF9E2AF)
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                sr['status'] as String,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFF9E2AF),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                sr['requested_by'] as String,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: cs.onSurface
                                                        .withValues(
                                                            alpha: 0.4)),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          sr['description'] as String,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: cs.onSurface),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(msg),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }
}

class _InProgressCard extends StatefulWidget {
  final Request request;
  final String mainTypeName;
  final String subTypeName;
  final VoidCallback onViewStaff;
  final VoidCallback onRequestEquipment;
  final VoidCallback onMarkComplete;

  const _InProgressCard({
    required this.request,
    required this.mainTypeName,
    required this.subTypeName,
    required this.onViewStaff,
    required this.onRequestEquipment,
    required this.onMarkComplete,
  });

  @override
  State<_InProgressCard> createState() => _InProgressCardState();
}

class _InProgressCardState extends State<_InProgressCard> {
  final _networkClient = NetworkClient();
  String? _startedByEmail;
  String? _startedByRole;
  List<String> _assignedToEmails = [];
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
        _startedByRole = lastTrack['performed_by_role'] as String?;
        final performedById = lastTrack['performed_by'] as String?;
        if (performedById != null) {
          try {
            final emailRes =
                await _networkClient.get('/users/emails?ids=$performedById');
            if (emailRes.data is Map) {
              _startedByEmail =
                  (emailRes.data as Map)[performedById]?.toString();
            }
          } catch (_) {}
        }
      }
      final assignRes =
          await _networkClient.get('/assignments/request/${widget.request.id}');
      final active = (assignRes.data as List)
          .where((a) => a['is_active'] == true)
          .toList();
      final ids = active.map((a) => a['staff_id'] as String).toSet().toList();
      if (ids.isNotEmpty) {
        try {
          final q = ids.map((id) => 'ids=$id').join('&');
          final res = await _networkClient.get('/users/emails?$q');
          if (res.data is Map) {
            _assignedToEmails =
                (res.data as Map).values.map((v) => v.toString()).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    if (mounted) setState(() => _extraLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const accent = Color(0xFFF9E2AF);
    final request = widget.request;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.work_rounded,
                            color: accent, size: 20),
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
                              color: cs.onSurface),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Main Type', value: widget.mainTypeName),
                  const SizedBox(height: 3),
                  _InfoRow(label: 'Sub Type', value: widget.subTypeName),
                  const SizedBox(height: 3),
                  _InfoRow(label: 'Updated at', value: _fmt(request.updatedAt)),
                  if (_extraLoading) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: cs.onSurface.withValues(alpha: 0.3)),
                    ),
                  ] else ...[
                    if (_startedByRole != null || _startedByEmail != null) ...[
                      const SizedBox(height: 3),
                      _InfoRow(
                        label: 'Started by',
                        value: [
                          if (_startedByRole != null) _startedByRole!,
                          if (_startedByEmail != null) _startedByEmail!,
                        ].join(' · '),
                      ),
                    ],
                    if (_assignedToEmails.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _InfoRow(
                          label: 'Assigned to',
                          value: _assignedToEmails.join(', ')),
                    ],
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onViewStaff,
                    icon: const Icon(Icons.people_rounded, size: 16),
                    label: const Text('View Assigned Staff',
                        style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: widget.onRequestEquipment,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF89B4FA),
                      side: const BorderSide(
                          color: Color(0xFF89B4FA), width: 0.8),
                    ),
                    icon: const Icon(Icons.shopping_cart_rounded, size: 16),
                    label: const Text('Request Equipment',
                        style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: widget.onMarkComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA6E3A1),
                      foregroundColor: Colors.black87,
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Mark as Complete',
                        style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime date) => '${date.day}/${date.month}/${date.year} '
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
          child: Text('$label:',
              style: TextStyle(
                  fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45))),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withValues(alpha: 0.8))),
        ),
      ],
    );
  }
}
