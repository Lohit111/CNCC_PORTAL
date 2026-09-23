import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cncc_portal/core/utils/file_opener.dart';
import 'package:cncc_portal/domain/entities/request_detail_entity.dart';
import 'package:cncc_portal/domain/entities/request_file_entity.dart';
import 'package:cncc_portal/presentation/providers/auth_provider.dart';
import 'package:cncc_portal/presentation/providers/admin_provider.dart';
import 'package:cncc_portal/presentation/providers/request_file_provider.dart';
import 'package:cncc_portal/services/file_service.dart';

// ---------------------------------------------------------------------------
// Helper Methods
// ---------------------------------------------------------------------------

/// Maps a request status to the adminProvider category key so the notifier
/// can be found and refreshed after deletion.
String categoryForStatus(String status) {
  switch (status) {
    case 'RAISED':
      return 'raised';
    case 'REPLIED':
      return 'replied';
    case 'ASSIGNED':
      return 'assigned';
    case 'REASSIGN_REQUESTED':
      return 'reassign-requested';
    case 'IN_PROGRESS':
      return 'inprogress';
    default:
      return 'archive';
  }
}

String raiserDisplay(RequestDetail detail) {
  final u = detail.users[detail.request.raisedBy];
  if (u == null) return detail.request.raisedBy;
  final name = (u.name != null && u.name!.trim().isNotEmpty) ? u.name! : null;
  return name != null ? '$name · ${u.email}' : u.email;
}

Color statusColor(String s) {
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

Color srStatusColor(String s) {
  switch (s) {
    case 'PENDING':
      return const Color(0xFFF9E2AF);
    case 'APPROVED':
      return const Color(0xFF94E2D5);
    case 'REJECTED':
      return const Color(0xFFF38BA8);
    case 'FULFILLED':
      return const Color(0xFFA6E3A1);
    default:
      return const Color(0xFF6C7086);
  }
}

String fmtFull(DateTime date) =>
    '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

IconData fileIcon(String contentType) {
  if (contentType.startsWith('image/')) return Icons.image_rounded;
  if (contentType.startsWith('video/')) return Icons.video_file_rounded;
  if (contentType.startsWith('audio/')) return Icons.audio_file_rounded;
  if (contentType == 'application/pdf') return Icons.picture_as_pdf_rounded;
  return Icons.insert_drive_file_rounded;
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

/// Show edit dialog for room and department
void showEditDialog(BuildContext context, WidgetRef ref, RequestDetail detail) {
  final req = detail.request;
  final roomController = TextEditingController(text: req.roomNo);
  final deptController = TextEditingController(text: req.department);
  
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Edit Request'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room field
            TextField(
              controller: roomController,
              decoration: const InputDecoration(
                labelText: 'Room',
                hintText: 'e.g., A001',
              ),
            ),
            const SizedBox(height: 16),
            
            // Department field
            TextField(
              controller: deptController,
              decoration: const InputDecoration(
                labelText: 'Department',
                hintText: 'e.g., Admin',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Call edit endpoint
            final room = roomController.text.trim();
            final dept = deptController.text.trim();
            if (room.isEmpty || dept.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all fields')),
              );
              return;
            }
            
            try {
              // Call the admin provider's editRequest function
              final ok = await ref
                  .read(adminProvider(categoryForStatus(req.status)).notifier)
                  .editRequest(req.id, room, dept);
              
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Request updated successfully' : 'Failed to update request'),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Delete Tile Widget
// ---------------------------------------------------------------------------

class DeleteTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const DeleteTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.45)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: cs.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Widget
// ---------------------------------------------------------------------------

class Section extends StatelessWidget {
  final String title;
  final Widget child;
  const Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withValues(alpha: 0.5),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Detail Row Widget
// ---------------------------------------------------------------------------

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Call Creator Row Widget
// ---------------------------------------------------------------------------

class CallCreatorRow extends StatelessWidget {
  final RequestDetail detail;
  const CallCreatorRow({required this.detail});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final raiser = detail.users[detail.request.raisedBy];
    final phone = raiser?.phone;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.call_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Call Creator',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone ?? 'No phone number on file',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: phone != null
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
          if (phone != null)
            IconButton(
              icon: Icon(Icons.phone_forwarded_rounded, color: cs.primary),
              tooltip: 'Open dialer',
              onPressed: () async {
                final uri = Uri(scheme: 'tel', path: phone);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Download Request Form Button Widget
// ---------------------------------------------------------------------------

class DownloadRequestFormButton extends ConsumerStatefulWidget {
  final String requestId;

  const DownloadRequestFormButton({required this.requestId});

  @override
  ConsumerState<DownloadRequestFormButton> createState() =>
      _DownloadRequestFormButtonState();
}

class _DownloadRequestFormButtonState
    extends ConsumerState<DownloadRequestFormButton> {
  bool _isDownloading = false;

  Future<void> _downloadForm() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      // Call the requestFileProvider's downloadFormPdf function
      final result = await ref
          .read(requestFileProvider(widget.requestId).notifier)
          .downloadFormPdf(widget.requestId);

      if (!mounted) return;

      await openFileBytes(
        bytes: result.bytes,
        fileName: result.fileName,
        contentType: result.contentType,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download form: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.file_download_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Download Request Form',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Download filled PDF form',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: _isDownloading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  )
                : Icon(Icons.download_rounded, color: cs.primary),
            tooltip: 'Download form',
            onPressed: _isDownloading ? null : _downloadForm,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Attachments Section Widget
// ---------------------------------------------------------------------------

class AttachmentsSection extends ConsumerStatefulWidget {
  final String requestId;
  final String raisedBy;

  const AttachmentsSection({required this.requestId, required this.raisedBy});

  @override
  ConsumerState<AttachmentsSection> createState() =>
      _AttachmentsSectionState();
}

class _AttachmentsSectionState extends ConsumerState<AttachmentsSection> {
  bool _isUploading = false;

  /// Tracks which file is currently being downloaded (by file id).
  String? _downloadingFileId;

  Future<void> _pickAndUpload() async {
    final files = await FileService.showFilePickerModal(context);
    if (files.isEmpty) return;

    if (!mounted) return; // Exit early if widget was disposed during modal

    setState(() => _isUploading = true);
    try {
      await ref
          .read(requestFileProvider(widget.requestId).notifier)
          .upload(files);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Downloads the file bytes through the server proxy, then opens/downloads
  /// the file using the platform-appropriate handler.
  Future<void> _openFile(RequestFile file) async {
    if (_downloadingFileId != null) return; // already downloading one

    setState(() => _downloadingFileId = file.id);

    try {
      final result = await ref
          .read(requestFileProvider(widget.requestId).notifier)
          .downloadFile(file);

      await openFileBytes(
        bytes: result.bytes,
        fileName: result.fileName,
        contentType: result.contentType,
      );
    } catch (e, st) {
      debugPrint('_openFile error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingFileId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filesAsync = ref.watch(requestFileProvider(widget.requestId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        filesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => Text(
            'Failed to load attachments',
            style: TextStyle(fontSize: 12, color: cs.error),
          ),
          data: (files) {
            if (files.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'No attachments',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              );
            }

            return Column(
              children: files.map((file) {
                final isDownloading = _downloadingFileId == file.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: isDownloading ? null : () => _openFile(file),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              fileIcon(file.contentType),
                              size: 20,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  formatFileSize(file.fileSize),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        cs.onSurface.withValues(alpha: 0.45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isDownloading)
                            const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(
                              Icons.download_rounded,
                              size: 17,
                              color: cs.onSurface.withValues(alpha: 0.4),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),

        // Upload button — only visible to the user who raised the request
        if (ref.watch(authProvider).user?.id == widget.raisedBy)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickAndUpload,
              icon: _isUploading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_file_rounded, size: 16),
                        SizedBox(width: 6),
                        Icon(Icons.camera_alt_rounded, size: 16),
                      ],
                    ),
              label: Text(_isUploading ? 'Uploading...' : 'Add Files or Capture'),
            ),
          ),
      ],
    );
  }
}
