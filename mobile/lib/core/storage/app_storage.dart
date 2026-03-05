import 'dart:io';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

Future<String> saveQrToGallery(List<int> bytes, String filename) async {
  final tmp = await getTemporaryDirectory();
  final tmpFile = File('${tmp.path}/$filename');
  await tmpFile.writeAsBytes(bytes, flush: true);

  final hasAccess = await Gal.hasAccess(toAlbum: true);
  if (!hasAccess) {
    final granted = await Gal.requestAccess(toAlbum: true);
    if (!granted) {
      throw Exception('Gallery permission denied');
    }
  }

  await Gal.putImage(tmpFile.path, album: 'QRCodet');
  final path = tmpFile.path;
  await tmpFile.delete();
  return path;
}

Future<Directory> resolveAppCacheDirectory() async {
  final base = await getApplicationDocumentsDirectory();
  final folder = Directory('${base.path}/QRCodetGallery');
  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }
  return folder;
}

Future<Directory> resolveSaveDirectory(String? customRoot) async {
  if (customRoot != null && customRoot.isNotEmpty) {
    final custom = Directory(customRoot);
    if (!await custom.exists()) {
      await custom.create(recursive: true);
    }
    return custom;
  }
  if (Platform.isAndroid) {
    final dcimFolder = Directory('/storage/emulated/0/DCIM/QRCodetGallery');
    try {
      if (!await dcimFolder.exists()) {
        await dcimFolder.create(recursive: true);
      }
      return dcimFolder;
    } catch (_) {
      // Scoped-storage/device restrictions can block direct shared-path writes.
      // Fall back to app-local storage so save flow remains functional.
    }
  }
  return resolveAppCacheDirectory();
}
