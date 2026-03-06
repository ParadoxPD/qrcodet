import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:screenshot/screenshot.dart';

import '../../core/models/app_models.dart';
import 'app_store.dart';

abstract class StoreModuleProvider extends ChangeNotifier {
  AppStore? _store;

  AppStore get store {
    final value = _store;
    if (value == null) {
      throw StateError('StoreModuleProvider is not attached to AppStore.');
    }
    return value;
  }

  void attach(AppStore nextStore) {
    if (identical(_store, nextStore)) return;
    _store?.removeListener(_relay);
    _store = nextStore;
    _store?.addListener(_relay);
    notifyListeners();
  }

  void _relay() => notifyListeners();

  @override
  void dispose() {
    _store?.removeListener(_relay);
    super.dispose();
  }
}

class ShellProvider extends StoreModuleProvider {
  AppUiState get ui => store.ui;
  ThemeData get materialTheme => store.materialTheme;
  ThemeSpec get appTheme => store.appTheme;
  GlobalKey<NavigatorState> get navigatorKey => store.navigatorKey;
  GlobalKey<ScaffoldMessengerState> get scaffoldMessengerKey => store.scaffoldMessengerKey;
  void setTabIndex(int value) => store.setTabIndex(value);
}

class CreateProvider extends StoreModuleProvider {
  List<ThemeSpec> get themes => store.themes;
  List<UseCaseSpec> get qrUseCases => store.qrUseCases;
  List<UseCaseSpec> get barcodeUseCases => store.barcodeUseCases;
  CodeMode get mode => store.mode;
  set mode(CodeMode value) => store.mode = value;
  Map<String, dynamic> get currentValues => store.currentValues;
  UseCaseSpec get selectedUseCase => store.selectedUseCase;
  ThemeData get materialTheme => store.materialTheme;
  ThemeSpec get activeTheme => store.activeTheme;
  String get payload => store.payload;
  String get payloadError => store.payloadError;
  String get header => store.header;
  set header(String value) => store.header = value;
  String get footer => store.footer;
  set footer(String value) => store.footer = value;
  String get generatorThemeId => store.generatorThemeId;
  set generatorThemeId(String value) => store.generatorThemeId = value;
  String get frameId => store.frameId;
  set frameId(String value) => store.frameId = value;
  String get qrStyleId => store.qrStyleId;
  set qrStyleId(String value) => store.qrStyleId = value;
  String get cornerStyleId => store.cornerStyleId;
  set cornerStyleId(String value) => store.cornerStyleId = value;
  String get qrErrorLevel => store.qrErrorLevel;
  set qrErrorLevel(String value) => store.qrErrorLevel = value;
  bool get saving => store.saving;
  bool get sharing => store.sharing;
  String get lastSavedPath => store.lastSavedPath;
  String get presetName => store.presetName;
  set presetName(String value) => store.presetName = value;
  List<GeneratorPreset> get presets => store.presets;
  ScrollPhysics get smoothScroll => store.smoothScroll;
  ScreenshotController get previewShot => store.previewShot;

  void runSetState(VoidCallback updates) => store.runSetState(updates);
  void setUseCase(String id) => store.setUseCase(id);
  void setField(String fieldName, dynamic value) => store.setField(fieldName, value);
  void setRuntimeMessage(String value) => store.setRuntimeMessage(value);
  FocusNode focusNodeForField(String fieldName) => store.focusNodeForField(fieldName);
  Future<void> savePreset() => store.savePreset();
  Future<void> loadPreset(GeneratorPreset preset) => store.loadPreset(preset);
  Future<void> deletePreset(String id) => store.deletePreset(id);
  Future<void> saveGeneratedCode({required Future<Uint8List?> Function() captureBytes}) {
    return store.saveGeneratedCode(captureBytes: captureBytes);
  }

  Future<void> shareGeneratedCode({required Future<Uint8List?> Function() captureBytes}) {
    return store.shareGeneratedCode(captureBytes: captureBytes);
  }
}

class ScanProvider extends StoreModuleProvider {
  MobileScannerController buildScannerController() => store.buildScannerController();
  Future<void> handleScan(Barcode barcode) => store.handleScan(barcode);
  Future<void> analyzeImageFromGallery() => store.analyzeImageFromGallery();
  bool get hapticsEnabled => store.settings.hapticsEnabled;
  ScanInsight? get scanInsight => store.scanInsight;
  List<ScanRecord> get history => store.history;
  DateFormat get dateFormat => store.dateFormat;
  void restoreHistory(ScanRecord record) => store.restoreHistory(record);
}

class GalleryProvider extends StoreModuleProvider {
  Future<Directory> saveDirectory() => store.saveDirectory();
  ScrollPhysics get smoothScroll => store.smoothScroll;
  AppSettings get settings => store.settings;
  DateFormat get dateFormat => store.dateFormat;
  void runSetState(VoidCallback updates) => store.runSetState(updates);
}

class SettingsProvider extends StoreModuleProvider {
  ScrollPhysics get smoothScroll => store.smoothScroll;
  List<ThemeSpec> get themes => store.themes;
  AppSettings get settings => store.settings;
  String get lastSavedPath => store.lastSavedPath;
  List<ScanRecord> get history => store.history;
  String get generatorThemeId => store.generatorThemeId;
  set generatorThemeId(String value) => store.generatorThemeId = value;
  String get frameId => store.frameId;
  set frameId(String value) => store.frameId = value;

  Future<void> updateSetting(AppSettings next) => store.updateSetting(next);
  void runSetState(VoidCallback updates) => store.runSetState(updates);
  Future<void> pickSaveDirectory() => store.pickSaveDirectory();
  Future<void> openSaveFolderAction() => store.openSaveFolderAction();
  Future<void> clearHistory() => store.clearHistory();
  Future<void> updateHistoryLimit(int nextLimit) => store.updateHistoryLimit(nextLimit);
}
