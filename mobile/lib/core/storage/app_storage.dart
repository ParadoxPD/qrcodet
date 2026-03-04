import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<Directory> resolveSaveDirectory(String? customRoot) async {
  if (customRoot != null && customRoot.isNotEmpty) {
    final custom = Directory(customRoot);
    if (!await custom.exists()) {
      await custom.create(recursive: true);
    }
    return custom;
  }
  final Directory? external = Platform.isAndroid ? await getExternalStorageDirectory() : null;
  if (Platform.isAndroid && external != null) {
    final String currentPath = external.path;
    const marker = '/Android/data/';
    final markerIndex = currentPath.indexOf(marker);
    if (markerIndex != -1) {
      final String targetRoot = currentPath.substring(0, markerIndex + marker.length);
      final Directory preferred = Directory('${targetRoot}com.paradox.qrcodet/files/QRCodetGallery');
      try {
        if (!await preferred.exists()) {
          await preferred.create(recursive: true);
        }
        return preferred;
      } catch (_) {
        // Fall through to app-specific default path.
      }
    }
  }
  final Directory base = external ?? await getApplicationDocumentsDirectory();
  final Directory folder = Directory('${base.path}/QRCodetGallery');
  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }
  return folder;
}
