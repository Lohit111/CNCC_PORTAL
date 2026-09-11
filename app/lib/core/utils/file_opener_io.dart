import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Writes [bytes] to the system temp directory as [fileName] then opens it
/// with the platform's default app for [contentType].
Future<void> openFileBytes({
  required Uint8List bytes,
  required String fileName,
  required String contentType,
}) async {
  final dir = await getTemporaryDirectory();
  final filePath = '${dir.path}/$fileName';
  await File(filePath).writeAsBytes(bytes, flush: true);

  final result = await OpenFilex.open(filePath);

  if (result.type != ResultType.done) {
    throw Exception('Could not open file: ${result.message}');
  }
}
