import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/app_models.dart';
import '../../core/storage/app_storage.dart';

class SaveCodeResult {
  SaveCodeResult({required this.message, required this.savedPath, required this.folderPath});

  final String message;
  final String? savedPath;
  final String? folderPath;
}

class ShareCodeResult {
  ShareCodeResult({required this.message});

  final String message;
}

class CreateService {
  Future<SaveCodeResult> saveGeneratedCode({
    required String payload,
    required String payloadError,
    required Future<Uint8List?> Function() captureBytes,
    required UseCaseSpec selectedUseCase,
    required Future<Directory> Function() saveDirectory,
  }) async {
    if (payload.isEmpty || payloadError.isNotEmpty) {
      return SaveCodeResult(
        message: payloadError.isNotEmpty ? payloadError : 'Fill required fields before saving.',
        savedPath: null,
        folderPath: null,
      );
    }

    final bytes = await captureBytes();
    if (bytes == null) {
      return SaveCodeResult(message: 'Save failed: Exception: Preview capture failed.', savedPath: null, folderPath: null);
    }

    final fileName = '${selectedUseCase.filenamePrefix}-${DateTime.now().millisecondsSinceEpoch}.png';
    try {
      await saveQrToGallery(bytes, fileName);
      final folder = await saveDirectory();
      final localFile = File('${folder.path}/$fileName');
      await localFile.writeAsBytes(bytes, flush: true);
      return SaveCodeResult(
        message: 'Saved to gallery (album: QRCodet) and local cache.',
        savedPath: localFile.path,
        folderPath: folder.path,
      );
    } on GalException catch (error) {
      return SaveCodeResult(message: 'Save failed: ${error.type.message}', savedPath: null, folderPath: null);
    } catch (error) {
      return SaveCodeResult(message: 'Save failed: $error', savedPath: null, folderPath: null);
    }
  }

  Future<ShareCodeResult> shareGeneratedCode({
    required String payload,
    required String payloadError,
    required Future<Uint8List?> Function() captureBytes,
    required UseCaseSpec selectedUseCase,
  }) async {
    if (payload.isEmpty || payloadError.isNotEmpty) {
      return ShareCodeResult(message: payloadError.isNotEmpty ? payloadError : 'Fill required fields before sharing.');
    }

    final bytes = await captureBytes();
    if (bytes == null) {
      return ShareCodeResult(message: 'Share failed: Exception: Preview capture failed.');
    }

    try {
      final fileName = '${selectedUseCase.filenamePrefix}-${DateTime.now().millisecondsSinceEpoch}.png';
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      final result = await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path)],
          text: 'Generated with QRCodet',
          title: 'Share QR Code',
        ),
      );
      return ShareCodeResult(message: result.status == ShareResultStatus.success ? 'Shared successfully.' : 'Share canceled.');
    } catch (error) {
      return ShareCodeResult(message: 'Share failed: $error');
    }
  }

  GeneratorPreset buildPreset({
    required String name,
    required CodeMode mode,
    required UseCaseSpec selectedUseCase,
    required Map<String, dynamic> currentValues,
    required String header,
    required String footer,
    required String themeId,
    required String frameId,
    required String qrStyleId,
    required String cornerStyleId,
    required String errorLevel,
  }) {
    return GeneratorPreset(
      id: 'preset-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      mode: mode.name,
      useCaseId: selectedUseCase.id,
      values: Map<String, dynamic>.from(currentValues),
      header: header,
      footer: footer,
      themeId: themeId,
      frameId: frameId,
      qrStyleId: qrStyleId,
      cornerStyleId: cornerStyleId,
      errorLevel: errorLevel,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
