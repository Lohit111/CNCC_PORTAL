import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_entity.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_request_detail_page.dart';

class AssignedRequestsPage extends StatefulWidget {
  const AssignedRequestsPage({super.key});

  @override
  State<AssignedRequestsPage> createState() => _AssignedRequestsPageState();
}

class _AssignedRequestsPageState extends State<AssignedRequestsPage> {
  final _networkClient = NetworkClient();
  List<Request> _requests = [];
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
      setState(() {
        _requests = (data['items'] as List)
            .map((json) => Request.fromJson(json))
            .where((req) =>
                (req.status == 'ASSIGNED' ||
                    req.status == 'IN_PROGRESS' ||
                    req.status == 'REASSIGN_REQUESTED') &&
                req.isActive == 'true')
            .toList();
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
        title: const Text('Assigned'),
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
            Text('No assigned requests',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        final accent = _statusColor(request.status);
        final isReassign = request.status == 'REASSIGN_REQUESTED';

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
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_statusIcon(request.status),
                            color: accent, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                request.statusDisplayText,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: accent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Reassign warning banner
                if (isReassign)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBA0AC).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                const Color(0xFFEBA0AC).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFEBA0AC), size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Staff has requested reassignment',
                              style: TextStyle(
                                  color: Color(0xFFEBA0AC),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),

                // Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      if (!isReassign) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _viewAssignments(context, request),
                            icon: const Icon(Icons.people_rounded, size: 16),
                            label: const Text('Staff',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminRequestDetailPage(requestId: request.id),
                            ),
                          ),
                          icon: const Icon(Icons.timeline_rounded, size: 16),
                          label: const Text('Timeline',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      if (isReassign) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _reassignStaff(context, request),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFAB387),
                              foregroundColor: Colors.black87,
                            ),
                            icon:
                                const Icon(Icons.swap_horiz_rounded, size: 16),
                            label: const Text('Reassign',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ASSIGNED':
        return const Color(0xFFCBA6F7);
      case 'IN_PROGRESS':
        return const Color(0xFFF9E2AF);
      case 'REASSIGN_REQUESTED':
        return const Color(0xFFEBA0AC);
      default:
        return const Color(0xFF6C7086);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'ASSIGNED':
        return Icons.assignment_ind_rounded;
      case 'IN_PROGRESS':
        return Icons.work_rounded;
      case 'REASSIGN_REQUESTED':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.circle;
    }
  }

  Future<void> _viewAssignments(BuildContext context, Request request) async {
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
            (res.data as Map).forEach((k, v) {
              staffEmails[k.toString()] = v.toString();
            });
          }
        } catch (_) {}
      }

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Assigned Staff'),
          content: activeAssignments.isEmpty
              ? const Text('No active staff assigned.')
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _reassignStaff(BuildContext context, Request request) async {
    try {
      final usersResponse = await _networkClient.get('/users/');
      final rolesResponse = await _networkClient.get('/roles/');

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
            title: const Text('Reassign to Staff'),
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
                child: const Text('Reassign'),
              ),
            ],
          ),
        ),
      );

      if (confirmed == true && selectedIds.isNotEmpty) {
        await _networkClient.post('/assignments/bulk', data: {
          'request_id': request.id,
          'staff_ids': selectedIds.toList(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${selectedIds.length} staff reassigned')),
          );
          _loadRequests();
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
}
