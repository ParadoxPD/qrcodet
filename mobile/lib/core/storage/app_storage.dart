import 'dart:io';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

Future<void> saveQrToGallery(List<int> bytes, String filename) async {
  final tmp = await getTemporaryDirectory();
  final tmpFile = File('${tmp.path}/$filename');
  await tmpFile.writeAsBytes(bytes, flush: true);
  try {
    final hasAccess = await Gal.hasAccess(toAlbum: true);
    if (!hasAccess) {
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) {
        throw Exception('Gallery permission denied');
      }
    }
    await Gal.putImage(tmpFile.path, album: 'QRCodet');
  } finally {
    if (await tmpFile.exists()) {
      await tmpFile.delete();
    }
  }
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
  return resolveAppCacheDirectory();
}
