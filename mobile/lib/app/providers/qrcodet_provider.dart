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
  Object? _lastSnapshot;

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
    _lastSnapshot = snapshotValue(store);
    _store?.addListener(_relay);
    notifyListeners();
  }

  /// Must return value-equality friendly snapshots (prefer records/primitives).
  Object snapshotValue(AppStore store);

  void _relay() {
    final nextSnapshot = snapshotValue(store);
    if (_lastSnapshot == nextSnapshot) return;
    _lastSnapshot = nextSnapshot;
    notifyListeners();
  }

  @override
  void dispose() {
    _store?.removeListener(_relay);
    super.dispose();
  }
}

class ShellProvider extends StoreModuleProvider {
  bool get loading => store.ui.loading;
  int get tabIndex => store.ui.tabIndex;
  String get runtimeMessage => store.ui.runtimeMessage;
  ThemeData get materialTheme => store.materialTheme;
  ThemeSpec get appTheme => store.appTheme;
  GlobalKey<NavigatorState> get navigatorKey => store.navigatorKey;
  GlobalKey<ScaffoldMessengerState> get scaffoldMessengerKey =>
      store.scaffoldMessengerKey;
  void setTabIndex(int value) => store.setTabIndex(value);

  @override
  Object snapshotValue(AppStore store) => (
    store.ui.loading,
    store.ui.tabIndex,
    store.ui.runtimeMessage,
    store.settings.appThemeId,
  );
}

class CreateProvider extends StoreModuleProvider {
  List<ThemeSpec> get themes => store.themes;
  List<UseCaseSpec> get qrUseCases => store.qrUseCases;
  List<UseCaseSpec> get barcodeUseCases => store.barcodeUseCases;
  CodeMode get mode => store.mode;
  set mode(CodeMode value) => store.setMode(value);
  Map<String, dynamic> get currentValues => store.currentValues;
  UseCaseSpec get selectedUseCase => store.selectedUseCase;
  ThemeData get materialTheme => store.materialTheme;
  ThemeSpec get activeTheme => store.activeTheme;
  String get payload => store.payload;
  String get payloadError => store.payloadError;
  String get header => store.header;
  set header(String value) => store.setHeader(value);
  String get footer => store.footer;
  set footer(String value) => store.setFooter(value);
  String get generatorThemeId => store.generatorThemeId;
  set generatorThemeId(String value) => store.setGeneratorThemeId(value);
  String get frameId => store.frameId;
  set frameId(String value) => store.setFrameId(value);
  String get qrStyleId => store.qrStyleId;
  set qrStyleId(String value) => store.setQrStyleId(value);
  String get cornerStyleId => store.cornerStyleId;
  set cornerStyleId(String value) => store.setCornerStyleId(value);
  String get qrErrorLevel => store.qrErrorLevel;
  set qrErrorLevel(String value) => store.setQrErrorLevel(value);
  bool get saving => store.saving;
  bool get sharing => store.sharing;
  String get lastSavedPath => store.lastSavedPath;
  String get presetName => store.presetName;
  set presetName(String value) => store.setPresetName(value);
  List<GeneratorPreset> get presets => store.presets;
  ScrollPhysics get smoothScroll => store.smoothScroll;
  ScreenshotController get previewShot => store.previewShot;

  void setUseCase(String id) => store.setUseCase(id);
  void setField(String fieldName, dynamic value) =>
      store.setField(fieldName, value);
  void setRuntimeMessage(String value) => store.setRuntimeMessage(value);
  FocusNode focusNodeForField(String fieldName) =>
      store.focusNodeForField(fieldName);
  Future<void> savePreset() => store.savePreset();
  Future<void> loadPreset(GeneratorPreset preset) => store.loadPreset(preset);
  Future<void> deletePreset(String id) => store.deletePreset(id);
  Future<void> saveGeneratedCode({
    required Future<Uint8List?> Function() captureBytes,
  }) {
    return store.saveGeneratedCode(captureBytes: captureBytes);
  }

  Future<void> shareGeneratedCode({
    required Future<Uint8List?> Function() captureBytes,
  }) {
    return store.shareGeneratedCode(captureBytes: captureBytes);
  }

  @override
  Object snapshotValue(AppStore store) => (
    store.mode,
    store.selectedQrId,
    store.selectedBarcodeId,
    store.payload,
    store.payloadError,
    store.header,
    store.footer,
    store.generatorThemeId,
    store.frameId,
    store.qrStyleId,
    store.cornerStyleId,
    store.qrErrorLevel,
    store.saving,
    store.sharing,
    store.lastSavedPath,
    store.presets.length,
    store.presetName,
    store.settings.appThemeId,
  );
}

class ScanProvider extends StoreModuleProvider {
  MobileScannerController buildScannerController() =>
      store.buildScannerController();
  Future<void> handleScan(Barcode barcode) => store.handleScan(barcode);
  Future<void> analyzeImageFromGallery() => store.analyzeImageFromGallery();
  bool get hapticsEnabled => store.settings.hapticsEnabled;
  ScanInsight? get scanInsight => store.scanInsight;
  List<ScanRecord> get history => store.history;
  DateFormat get dateFormat => store.dateFormat;
  void restoreHistory(ScanRecord record) => store.restoreHistory(record);

  @override
  Object snapshotValue(AppStore store) => (
    store.settings.focusProfile,
    store.settings.autoZoom,
    store.settings.preferFrontCamera,
    store.settings.hapticsEnabled,
    store.scanInsight?.payload,
    store.history.length,
    store.history.isEmpty ? '' : store.history.first.id,
  );
}

class GalleryProvider extends StoreModuleProvider {
  Future<Directory> saveDirectory() => store.saveDirectory();
  Future<List<FileSystemEntity>> loadGalleryEntities() =>
      store.loadGalleryEntities();
  Future<void> deleteGalleryEntity(String path) =>
      store.deleteGalleryEntity(path);
  Future<void> openGalleryEntityInFiles(String path) =>
      store.openGalleryEntityInFiles(path);
  Future<void> shareGalleryEntity(String path) =>
      store.shareGalleryEntity(path);
  ScrollPhysics get smoothScroll => store.smoothScroll;
  AppSettings get settings => store.settings;
  DateFormat get dateFormat => store.dateFormat;
  int get galleryVersion => store.galleryVersion;

  @override
  Object snapshotValue(AppStore store) =>
      (store.settings.saveDirectoryPath, store.galleryVersion);
}

class SettingsProvider extends StoreModuleProvider {
  ScrollPhysics get smoothScroll => store.smoothScroll;
  List<ThemeSpec> get themes => store.themes;
  AppSettings get settings => store.settings;
  String get lastSavedPath => store.lastSavedPath;
  List<ScanRecord> get history => store.history;
  String get generatorThemeId => store.generatorThemeId;
  set generatorThemeId(String value) => store.setGeneratorThemeId(value);
  String get frameId => store.frameId;
  set frameId(String value) => store.setFrameId(value);

  Future<void> updateSetting(AppSettings next) => store.updateSetting(next);
  Future<void> setGeneratorThemeAndPersist(String value) =>
      store.setGeneratorThemeAndPersist(value);
  Future<void> setDefaultFrameAndPersist(String value) =>
      store.setDefaultFrameAndPersist(value);
  Future<void> pickSaveDirectory() => store.pickSaveDirectory();
  Future<void> openSaveFolder() => store.openSaveFolder();
  Future<void> clearHistory() => store.clearHistory();
  Future<void> updateHistoryLimit(int nextLimit) =>
      store.updateHistoryLimit(nextLimit);

  @override
  Object snapshotValue(AppStore store) => (
    store.settings.appThemeId,
    store.settings.generatorThemeId,
    store.settings.focusProfile,
    store.settings.autoZoom,
    store.settings.preferFrontCamera,
    store.settings.hapticsEnabled,
    store.settings.historyLimit,
    store.settings.saveRootPath,
    store.settings.saveDirectoryPath,
    store.settings.defaultFrameId,
    store.settings.defaultHeader,
    store.settings.defaultFooter,
    store.history.length,
    store.lastSavedPath,
    store.generatorThemeId,
    store.frameId,
  );
}
