import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/app_models.dart';

const String prefsSettingsKey = 'qrcodet.settings.v1';
const String prefsHistoryKey = 'qrcodet.scan_history.v1';
const String prefsPresetsKey = 'qrcodet.presets.mobile.v1';

class AppBootstrapData {
  AppBootstrapData({required this.settings, required this.history, required this.presets});

  final AppSettings settings;
  final List<ScanRecord> history;
  final List<GeneratorPreset> presets;
}

class AppPersistenceService {
  Future<AppBootstrapData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawSettings = prefs.getString(prefsSettingsKey);
    final rawHistory = prefs.getString(prefsHistoryKey);
    final rawPresets = prefs.getString(prefsPresetsKey);

    final settings = rawSettings == null
        ? AppSettings.defaults()
        : AppSettings.fromJson(jsonDecode(rawSettings) as Map<String, dynamic>);
    final history = rawHistory == null
        ? <ScanRecord>[]
        : (jsonDecode(rawHistory) as List<dynamic>)
            .map((item) => ScanRecord.fromJson(item as Map<String, dynamic>))
            .toList();
    final presets = rawPresets == null
        ? <GeneratorPreset>[]
        : (jsonDecode(rawPresets) as List<dynamic>)
            .map((item) => GeneratorPreset.fromJson(item as Map<String, dynamic>))
            .toList();

    return AppBootstrapData(settings: settings, history: history, presets: presets);
  }

  Future<void> persistSettings(AppSettings next) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsSettingsKey, jsonEncode(next.toJson()));
  }

  Future<void> persistHistory(List<ScanRecord> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsHistoryKey, jsonEncode(history.map((e) => e.toJson()).toList()));
  }

  Future<void> persistPresets(List<GeneratorPreset> presets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsPresetsKey, jsonEncode(presets.map((e) => e.toJson()).toList()));
  }
}
