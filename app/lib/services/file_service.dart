import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

/// File service for picking files and capturing images.
/// Provides centralized file/image selection logic.
class FileService {
  static final _imagePicker = ImagePicker();

  /// Pick multiple files from device storage.
  /// Returns list of PlatformFile, or null if cancelled.
  static Future<List<PlatformFile>?> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
      );
      return result?.files;
    } catch (e) {
      debugPrint('pickFiles error: $e');
      return null;
    }
  }

  /// Capture a single image from device camera.
  /// Returns PlatformFile wrapping the captured image, or null if cancelled.
  static Future<PlatformFile?> captureImage() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (photo == null) return null;

      // Convert XFile to PlatformFile for consistency
      final bytes = await photo.readAsBytes();
      
      // Generate filename: uploaded-HH:MM (e.g., uploaded-14:30)
      final now = DateTime.now();
      final filename = 'uploaded-${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}.jpg';
      
      return PlatformFile(
        name: filename,
        size: bytes.length,
        bytes: bytes,
      );
    } catch (e) {
      debugPrint('captureImage error: $e');
      return null;
    }
  }

  /// Show modal to pick files or capture image.
  /// Returns list of PlatformFile, or empty list if cancelled.
  static Future<List<PlatformFile>> showFilePickerModal(
    BuildContext context,
  ) async {
    final result = await showModalBottomSheet<List<PlatformFile>>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Title
              Text(
                'Add Files',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              // Pick files button
              ListTile(
                leading: const Icon(Icons.attach_file_rounded),
                title: const Text('Pick Files'),
                subtitle: const Text('From device storage'),
                onTap: () async {
                  final files = await pickFiles();
                  if (ctx.mounted) {
                    Navigator.pop(ctx, files);
                  }
                },
              ),

              // Capture image button
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Capture Image'),
                subtitle: const Text('Using device camera'),
                onTap: () async {
                  final image = await captureImage();
                  if (image != null && ctx.mounted) {
                    Navigator.pop(ctx, [image]);
                  }
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    return result ?? [];
  }
}
