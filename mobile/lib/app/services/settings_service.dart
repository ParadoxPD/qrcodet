import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../../core/models/app_models.dart';
import '../../core/storage/app_storage.dart';

class SettingsService {
  Future<Directory?> pickSaveDirectory() async {
    final selected = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select QRCodet save folder');
    if (selected == null || selected.isEmpty) return null;
    return resolveSaveDirectory(selected);
  }

  (AppSettings, List<ScanRecord>) applyHistoryLimit({
    required AppSettings settings,
    required List<ScanRecord> history,
    required int nextLimit,
  }) {
    final nextHistory = history.take(nextLimit).toList();
    final nextSettings = settings.copyWith(historyLimit: nextLimit);
    return (nextSettings, nextHistory);
  }
}
