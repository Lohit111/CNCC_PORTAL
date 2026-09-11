import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/request_file_entity.dart';

class RequestFileNotifier
    extends FamilyAsyncNotifier<List<RequestFile>, String> {
  final _client = NetworkClient();

  @override
  Future<List<RequestFile>> build(String requestId) {
    return _fetch(requestId);
  }

  Future<List<RequestFile>> _fetch(String requestId) async {
    final response = await _client.get(
      '/request-files/$requestId',
    );

    final files = response.data['files'] as List;

    return files
        .map(
          (file) => RequestFile.fromJson(
            Map<String, dynamic>.from(file),
          ),
        )
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => _fetch(arg),
    );
  }

  /// Downloads a single file's bytes through the server proxy and returns them
  /// together with the file's name and content-type.
  ///
  /// Throws on network or server error.
  Future<({Uint8List bytes, String fileName, String contentType})>
      downloadFile(RequestFile file) async {
    final response = await _client.get(
      '/request-files/${file.requestId}/${file.id}/download',
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 2),
      ),
    );

    // Dio returns Uint8List for ResponseType.bytes on mobile, but the static
    // type is dynamic. Handle both Uint8List and List<int> safely.
    final dynamic raw = response.data;
    final Uint8List bytes;
    if (raw is Uint8List) {
      bytes = raw;
    } else if (raw is List<int>) {
      bytes = Uint8List.fromList(raw);
    } else {
      // Fallback: encode whatever we got via its toString bytes.
      throw StateError(
        'Unexpected response data type for binary download: ${raw.runtimeType}',
      );
    }

    return (
      bytes: bytes,
      fileName: file.fileName,
      contentType: file.contentType,
    );
  }

  Future<void> upload(List<PlatformFile> files) async {
    debugPrint('RequestFileNotifier.upload() called');
    debugPrint('Number of files: ${files.length}');

    if (files.isEmpty) return;

    final formData = FormData();

    for (final file in files) {
      debugPrint(
        'Preparing ${file.name}: bytes=${file.bytes?.length}',
      );

      if (file.bytes == null) {
        throw Exception('Could not read ${file.name}');
      }

      formData.files.add(
        MapEntry(
          'files',
          MultipartFile.fromBytes(
            file.bytes!,
            filename: file.name,
          ),
        ),
      );
    }

    debugPrint('Sending POST /request-files/$arg');

    await _client.post(
      '/request-files/$arg',
      data: formData,
    );

    debugPrint('POST /request-files/$arg completed');

    await refresh();
  }
}

final requestFileProvider =
    AsyncNotifierProviderFamily<RequestFileNotifier, List<RequestFile>, String>(
  RequestFileNotifier.new,
);
