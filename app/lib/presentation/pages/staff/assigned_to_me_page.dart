import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/core/utils/error_handler.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/domain/entities/type_entity.dart';
import 'package:cncc_portal/presentation/providers/auth_provider.dart';

class AssignedToMePage extends ConsumerStatefulWidget {
  const AssignedToMePage({super.key});

  @override
  ConsumerState<AssignedToMePage> createState() => _AssignedToMePageState();
}

class _AssignedToMePageState extends ConsumerState<AssignedToMePage> {
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
              req.status == 'ASSIGNED' &&
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
        title: const Text('Assigned to Me'),
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
            Text('No new assignments',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            Text('Requests assigned to you will appear here',
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
        return _AssignedCard(
          request: request,
          mainTypeName: _mainTypeNames[request.mainTypeId] ?? '—',
          subTypeName: _subTypeNames[request.subTypeId] ?? '—',
          onViewStaff: () => _viewAssignedStaff(request),
          onStartWork: () => _showStartWorkDialog(request),
          onReassign: () => _showReassignDialog(request),
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

  Future<void> _showStartWorkDialog(Request request) async {
    final commentController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Working'),
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
                labelText: 'Comment (optional)',
                hintText: 'What are you planning to do?',
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
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _networkClient.put('/requests/${request.id}', data: {
          'status': 'IN_PROGRESS',
          'comment': commentController.text,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Status updated to In Progress')),
          );
          _loadRequests();
        }
      } catch (e) {
        if (mounted) {
          final msg = ErrorHandler.handle(e).message;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.sync_problem_rounded, color: Color(0xFFF9E2AF)),
                  SizedBox(width: 8),
                  Text('Stale State'),
                ],
              ),
              content: Text(msg),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadRequests();
                  },
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> _showReassignDialog(Request request) async {
    final commentController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Request Reassignment'),
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
                  labelText: 'Reason for Reassignment (required)',
                  hintText: 'Why do you need this reassigned?',
                ),
                maxLines: 3,
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
              onPressed: commentController.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFAB387),
                foregroundColor: Colors.black87,
              ),
              child: const Text('Request Reassignment'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _networkClient.put('/requests/${request.id}', data: {
          'status': 'REASSIGN_REQUESTED',
          'comment': commentController.text,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reassignment requested')),
          );
          _loadRequests();
        }
      } catch (e) {
        if (mounted) {
          final msg = ErrorHandler.handle(e).message;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.sync_problem_rounded, color: Color(0xFFF9E2AF)),
                  SizedBox(width: 8),
                  Text('Stale State'),
                ],
              ),
              content: Text(msg),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadRequests();
                  },
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }
      }
    }
  }
}

class _AssignedCard extends StatefulWidget {
  final Request request;
  final String mainTypeName;
  final String subTypeName;
  final VoidCallback onViewStaff;
  final VoidCallback onStartWork;
  final VoidCallback onReassign;

  const _AssignedCard({
    required this.request,
    required this.mainTypeName,
    required this.subTypeName,
    required this.onViewStaff,
    required this.onStartWork,
    required this.onReassign,
  });

  @override
  State<_AssignedCard> createState() => _AssignedCardState();
}

class _AssignedCardState extends State<_AssignedCard> {
  final _networkClient = NetworkClient();
  String? _assignedByEmail;
  String? _assignedByRole;
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
        _assignedByRole = lastTrack['performed_by_role'] as String?;
        final performedById = lastTrack['performed_by'] as String?;
        if (performedById != null) {
          try {
            final emailRes =
                await _networkClient.get('/users/emails?ids=$performedById');
            if (emailRes.data is Map) {
              _assignedByEmail =
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
    const accent = Color(0xFFCBA6F7);
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
                        child: const Icon(Icons.assignment_ind_rounded,
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
                    if (_assignedByRole != null ||
                        _assignedByEmail != null) ...[
                      const SizedBox(height: 3),
                      _InfoRow(
                        label: 'Assigned by',
                        value: [
                          if (_assignedByRole != null) _assignedByRole!,
                          if (_assignedByEmail != null) _assignedByEmail!,
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
                  ElevatedButton.icon(
                    onPressed: widget.onStartWork,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA6E3A1),
                      foregroundColor: Colors.black87,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Start Working',
                        style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: widget.onReassign,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Request Reassignment',
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
