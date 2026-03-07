import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:open_filex/open_filex.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/data/app_catalog.dart';
import '../../core/logic/generator_logic.dart';
import '../../core/logic/scan_parser.dart';
import '../../core/models/app_models.dart';
import '../../core/storage/app_storage.dart';
import '../services/app_persistence_service.dart';
import '../services/create_service.dart';
import '../services/scan_service.dart';
import '../services/settings_service.dart';

class AppUiState {
  AppUiState({
    this.loading = true,
    this.tabIndex = 0,
    this.runtimeMessage = '',
  });

  bool loading;
  int tabIndex;
  String runtimeMessage;
}

class AppStore extends ChangeNotifier {
  AppStore({
    AppPersistenceService? persistenceService,
    CreateService? createService,
    ScanService? scanService,
    SettingsService? settingsService,
  }) : _persistenceService = persistenceService ?? AppPersistenceService(),
       _createService = createService ?? CreateService(),
       _scanService = scanService ?? ScanService(),
       _settingsService = settingsService ?? SettingsService() {
    _valuesMap = createInitialValues(qrUseCases, barcodeUseCases);
  }

  final AppPersistenceService _persistenceService;
  final CreateService _createService;
  final ScanService _scanService;
  final SettingsService _settingsService;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final ScreenshotController previewShot = ScreenshotController();
  final ImagePicker _imagePicker = ImagePicker();
  final DateFormat dateFormat = DateFormat('dd MMM yyyy, HH:mm');
  final Map<String, FocusNode> _fieldFocusNodes = <String, FocusNode>{};

  final List<ThemeSpec> themes = buildThemeSpecs();
  final List<UseCaseSpec> qrUseCases = buildQrUseCases();
  final List<UseCaseSpec> barcodeUseCases = buildBarcodeUseCases();

  final AppUiState _ui = AppUiState();
  AppSettings _settings = AppSettings.defaults();
  List<ScanRecord> _history = <ScanRecord>[];
  List<GeneratorPreset> _presets = <GeneratorPreset>[];
  CodeMode _mode = CodeMode.qr;
  String _selectedQrId = 'upi';
  String _selectedBarcodeId = 'code128';
  Map<String, Map<String, dynamic>> _valuesMap =
      <String, Map<String, dynamic>>{};
  String _header = 'Scan & Pay';
  String _footer = 'Powered by QRCodet';
  String _generatorThemeId = 'noir';
  String _frameId = 'scan';
  String _qrStyleId = 'rounded';
  String _cornerStyleId = 'rounded';
  String _qrErrorLevel = 'M';
  String _lastSavedPath = '';
  String _presetName = '';
  ScanInsight? _scanInsight;
  bool _saving = false;
  bool _sharing = false;
  int _galleryVersion = 0;
  ThemeData? _cachedMaterialTheme;
  String? _cachedMaterialThemeId;
  PayloadResult? _cachedPayloadResult;
  String? _cachedPayloadKey;

  AppUiState get ui => _ui;
  AppSettings get settings => _settings;
  List<ScanRecord> get history => _history;
  List<GeneratorPreset> get presets => _presets;
  CodeMode get mode => _mode;
  String get selectedQrId => _selectedQrId;
  String get selectedBarcodeId => _selectedBarcodeId;
  String get header => _header;
  String get footer => _footer;
  String get generatorThemeId => _generatorThemeId;
  String get frameId => _frameId;
  String get qrStyleId => _qrStyleId;
  String get cornerStyleId => _cornerStyleId;
  String get qrErrorLevel => _qrErrorLevel;
  String get lastSavedPath => _lastSavedPath;
  String get presetName => _presetName;
  ScanInsight? get scanInsight => _scanInsight;
  bool get saving => _saving;
  bool get sharing => _sharing;
  int get galleryVersion => _galleryVersion;

  bool _disposed = false;
  static const ScrollPhysics _iosScroll = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );
  static const ScrollPhysics _defaultScroll = ClampingScrollPhysics();

  ScrollPhysics get smoothScroll {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _iosScroll;
      default:
        return _defaultScroll;
    }
  }

  UseCaseSpec get selectedUseCase {
    final source = mode == CodeMode.qr ? qrUseCases : barcodeUseCases;
    final selectedId = mode == CodeMode.qr ? selectedQrId : selectedBarcodeId;
    return source.firstWhere((item) => item.id == selectedId);
  }

  ThemeSpec get activeTheme => themes.firstWhere(
    (item) => item.id == generatorThemeId,
    orElse: () => themes.first,
  );
  ThemeSpec get appTheme => themes.firstWhere(
    (item) => item.id == settings.appThemeId,
    orElse: () => themes.first,
  );

  ThemeData _buildMaterialTheme() {
    final spec = themes.firstWhere(
      (item) => item.id == settings.appThemeId,
      orElse: () => themes.first,
    );
    final brightness = spec.mood == ThemeMood.dark
        ? Brightness.dark
        : Brightness.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: spec.accent,
          brightness: brightness,
        ).copyWith(
          primary: spec.accent,
          secondary: spec.dark,
          surface: spec.light,
          onSurface: brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          onSurfaceVariant: brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        );
    final textColor = brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    final baseFill = brightness == Brightness.dark
        ? const Color(0xFF1A1712)
        : Colors.white;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      canvasColor: brightness == Brightness.dark
          ? const Color(0xFF1A1712)
          : Colors.white,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF0E0D0A)
          : const Color(0xFFF5F1E7),
      cardTheme: CardThemeData(
        elevation: 0,
        color: brightness == Brightness.dark
            ? const Color(0xFF171510)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      textTheme: ThemeData(
        brightness: brightness,
      ).textTheme.apply(bodyColor: textColor, displayColor: textColor),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: baseFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: brightness == Brightness.dark
                ? const Color(0xFF322B20)
                : const Color(0xFFDFD7C9),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: spec.accent.withValues(
          alpha: brightness == Brightness.dark ? 0.28 : 0.2,
        ),
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF14110D)
            : const Color(0xFFF8F4EA),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF1A1712)
            : Colors.white,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: brightness == Brightness.dark
            ? const Color(0xFF1A1712)
            : Colors.white,
        textStyle: TextStyle(color: textColor),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? const Color(0xFFF0EAD9)
              : const Color(0xFF1B1812),
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: TextStyle(
          color: brightness == Brightness.dark
              ? const Color(0xFF1B1812)
              : const Color(0xFFF0EAD9),
          fontSize: 12,
        ),
        waitDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  ThemeData get materialTheme {
    if (_cachedMaterialThemeId == settings.appThemeId &&
        _cachedMaterialTheme != null) {
      return _cachedMaterialTheme!;
    }
    _cachedMaterialThemeId = settings.appThemeId;
    _cachedMaterialTheme = _buildMaterialTheme();
    return _cachedMaterialTheme!;
  }

  Color get appTextColor =>
      materialTheme.brightness == Brightness.dark ? Colors.white : Colors.black;

  Map<String, dynamic> get currentValues =>
      _valuesMap['${mode.name}:${selectedUseCase.id}'] ?? <String, dynamic>{};

  PayloadResult get _currentPayloadResult {
    // Build a lightweight cache key from the inputs that affect the payload.
    // currentValues is a Map so use its identity — it is always replaced
    // (not mutated in place) by setField, so identity comparison is correct.
    final key =
        '${mode.name}:${selectedUseCase.id}:${identityHashCode(currentValues)}';
    if (_cachedPayloadKey == key && _cachedPayloadResult != null) {
      return _cachedPayloadResult!;
    }
    _cachedPayloadKey = key;
    _cachedPayloadResult = buildPayload(mode, selectedUseCase, currentValues);
    return _cachedPayloadResult!;
  }

  String get payload => _currentPayloadResult.payload;

  String get payloadError => _currentPayloadResult.error;

  Future<void> initialize() async {
    final loaded = await _persistenceService.load();
    final shouldMigrateSaveDir =
        loaded.settings.saveRootPath.isEmpty ||
        loaded.settings.saveRootPath.contains('qrcodet_mobile') ||
        loaded.settings.saveRootPath.contains('/Android/data/');
    final saveDir = shouldMigrateSaveDir
        ? await _resolveBootstrapSaveDirectory()
        : await resolveSaveDirectory(loaded.settings.saveRootPath);

    _settings = loaded.settings.copyWith(
      saveRootPath: saveDir.path,
      saveDirectoryPath: saveDir.path,
    );
    _history = loaded.history.take(loaded.settings.historyLimit).toList();
    _presets = loaded.presets;
    _generatorThemeId = _settings.generatorThemeId;
    _header = _settings.defaultHeader;
    _footer = _settings.defaultFooter;
    _frameId = _settings.defaultFrameId;
    _ui.loading = false;
    _safeNotify();

    await _persistenceService.persistSettings(
      settings.copyWith(
        saveRootPath: saveDir.path,
        saveDirectoryPath: saveDir.path,
      ),
    );
  }

  Future<Directory> _resolveBootstrapSaveDirectory() async {
    if (Platform.isAndroid) {
      final legacy = Directory('/storage/emulated/0/DCIM/QRCodetGallery');
      try {
        if (await legacy.exists()) {
          final hasPng = legacy.listSync().any(
            (item) => item is File && item.path.toLowerCase().endsWith('.png'),
          );
          if (hasPng) {
            return legacy;
          }
        }
      } catch (_) {
        // Fall back to app directory below.
      }
    }
    return resolveSaveDirectory('');
  }

  void setTabIndex(int value) {
    if (ui.tabIndex == value) return;
    _ui.tabIndex = value;
    _safeNotify();
  }

  void setRuntimeMessage(String value) {
    if (ui.runtimeMessage == value) return;
    _ui.runtimeMessage = value;
    _safeNotify();
  }

  Future<void> updateSetting(AppSettings next) async {
    _settings = next;
    _safeNotify();
    await _persistenceService.persistSettings(next);
  }

  Future<void> setGeneratorThemeAndPersist(String value) async {
    if (_generatorThemeId == value && _settings.generatorThemeId == value) {
      return;
    }
    _generatorThemeId = value;
    _settings = _settings.copyWith(generatorThemeId: value);
    _safeNotify();
    await _persistenceService.persistSettings(_settings);
  }

  Future<void> setDefaultFrameAndPersist(String value) async {
    if (_frameId == value && _settings.defaultFrameId == value) return;
    _frameId = value;
    _settings = _settings.copyWith(defaultFrameId: value);
    _safeNotify();
    await _persistenceService.persistSettings(_settings);
  }

  void setField(String fieldName, dynamic value) {
    final key = '${mode.name}:${selectedUseCase.id}';
    final next = Map<String, dynamic>.from(
      _valuesMap[key] ?? <String, dynamic>{},
    );
    next[fieldName] = value;
    _valuesMap[key] = next;
    // Clear the runtime message if one is showing, but always notify
    // regardless — the QR preview must update on every keystroke.
    if (_ui.runtimeMessage.isNotEmpty) {
      _ui.runtimeMessage = '';
    }
    _safeNotify();
  }

  void setUseCase(String id) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (mode == CodeMode.qr) {
      _selectedQrId = id;
    } else {
      _selectedBarcodeId = id;
    }
    final defaults = selectedUseCase.defaults;
    _header = defaults['header']?.toString() ?? _header;
    _footer = defaults['footer']?.toString() ?? _footer;
    if (_ui.runtimeMessage.isNotEmpty) {
      _ui.runtimeMessage = '';
    }
    _safeNotify();
  }

  Future<Directory> saveDirectory() async {
    return resolveSaveDirectory(settings.saveRootPath);
  }

  Future<void> saveGeneratedCode({
    required Future<Uint8List?> Function() captureBytes,
  }) async {
    if (_disposed) return;
    if (payload.isEmpty || payloadError.isNotEmpty) {
      focusFirstMissingRequiredField();
      setRuntimeMessage(
        payloadError.isNotEmpty
            ? payloadError
            : 'Fill required fields before saving.',
      );
      return;
    }
    _saving = true;
    if (_ui.runtimeMessage.isNotEmpty) {
      _ui.runtimeMessage = '';
    }
    if (!_disposed) notifyListeners();
    try {
      final result = await _createService.saveGeneratedCode(
        payload: payload,
        payloadError: payloadError,
        captureBytes: captureBytes,
        selectedUseCase: selectedUseCase,
        saveDirectory: saveDirectory,
      );
      if (result.savedPath != null && result.folderPath != null) {
        _lastSavedPath = result.savedPath!;
        _galleryVersion += 1;
        showSaveSuccessNotice(result.savedPath!, result.folderPath!);
      }
      setRuntimeMessage(result.message);
    } finally {
      if (!_disposed) {
        _saving = false;
        notifyListeners();
      }
    }
  }

  Future<void> shareGeneratedCode({
    required Future<Uint8List?> Function() captureBytes,
  }) async {
    if (_disposed) return;
    if (payload.isEmpty || payloadError.isNotEmpty) {
      focusFirstMissingRequiredField();
      setRuntimeMessage(
        payloadError.isNotEmpty
            ? payloadError
            : 'Fill required fields before sharing.',
      );
      return;
    }
    _sharing = true;
    if (_ui.runtimeMessage.isNotEmpty) {
      _ui.runtimeMessage = '';
    }
    if (!_disposed) notifyListeners();
    try {
      final result = await _createService.shareGeneratedCode(
        payload: payload,
        payloadError: payloadError,
        captureBytes: captureBytes,
        selectedUseCase: selectedUseCase,
      );
      setRuntimeMessage(result.message);
    } finally {
      if (!_disposed) {
        _sharing = false;
        notifyListeners();
      }
    }
  }

  FocusNode focusNodeForField(String fieldName) {
    final key = '${mode.name}:${selectedUseCase.id}:$fieldName';
    return _fieldFocusNodes.putIfAbsent(key, () => FocusNode(debugLabel: key));
  }

  void focusFirstMissingRequiredField() {
    for (final field in selectedUseCase.fields.where((item) => item.required)) {
      final value = currentValues[field.name];
      final missing =
          value == null || (value is String && value.trim().isEmpty);
      if (!missing) continue;
      focusNodeForField(field.name).requestFocus();
      return;
    }
  }

  Future<void> pickSaveDirectory() async {
    final dir = await _settingsService.pickSaveDirectory();
    if (dir == null) return;
    final next = settings.copyWith(
      saveRootPath: dir.path,
      saveDirectoryPath: dir.path,
    );
    await updateSetting(next);
    _galleryVersion += 1;
    setRuntimeMessage('Default save folder changed to ${dir.path}');
  }

  Future<void> openSaveFolder() async {
    final path = _settings.saveDirectoryPath;
    if (path.isEmpty) {
      _showSnack('No save folder configured yet.');
      return;
    }

    if (Platform.isAndroid) {
      try {
        await AndroidIntent(
          action: 'android.intent.action.VIEW',
          type: 'resource/folder',
          data: Uri.file(path).toString(),
        ).launch();
      } catch (_) {
        await SharePlus.instance.share(ShareParams(text: path));
      }
    } else if (Platform.isIOS) {
      await SharePlus.instance.share(ShareParams(text: path));
    } else {
      final uri = Uri.file(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  void showSaveSuccessNotice(String filePath, String folderPath) {
    showSnackBar(
      SnackBar(
        content: Text('Saved QR. Folder: $folderPath'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: filePath));
          },
        ),
      ),
    );
  }

  void showSnackBar(SnackBar snackBar) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(snackBar);
  }

  void _showSnack(String message) {
    showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> savePreset() async {
    if (presetName.trim().isEmpty) return;
    final preset = _createService.buildPreset(
      name: presetName,
      mode: mode,
      selectedUseCase: selectedUseCase,
      currentValues: currentValues,
      header: header,
      footer: footer,
      themeId: generatorThemeId,
      frameId: frameId,
      qrStyleId: qrStyleId,
      cornerStyleId: cornerStyleId,
      errorLevel: qrErrorLevel,
    );
    _presets = <GeneratorPreset>[preset, ..._presets];
    _presetName = '';
    _safeNotify();
    await _persistenceService.persistPresets(presets);
  }

  Future<void> loadPreset(GeneratorPreset preset) async {
    _mode = preset.mode == CodeMode.barcode.name
        ? CodeMode.barcode
        : CodeMode.qr;
    if (preset.mode == CodeMode.barcode.name) {
      _selectedBarcodeId = preset.useCaseId;
    } else {
      _selectedQrId = preset.useCaseId;
    }
    _valuesMap['${preset.mode}:${preset.useCaseId}'] =
        Map<String, dynamic>.from(preset.values);
    _header = preset.header;
    _footer = preset.footer;
    _generatorThemeId = preset.themeId;
    _frameId = preset.frameId;
    _qrStyleId = preset.qrStyleId;
    _cornerStyleId = preset.cornerStyleId;
    _qrErrorLevel = preset.errorLevel;
    _ui.tabIndex = 0;
    _safeNotify();
  }

  Future<void> deletePreset(String id) async {
    _presets = _presets.where((item) => item.id != id).toList();
    _safeNotify();
    await _persistenceService.persistPresets(presets);
  }

  Future<void> analyzeImageFromGallery() async {
    if (_disposed) return;
    final barcode = await _scanService.analyzeImageFromGallery(
      imagePicker: _imagePicker,
    );
    try {
      if (barcode == null) {
        setRuntimeMessage('No QR or barcode found in the selected image.');
        return;
      }
      await handleScan(barcode);
    } catch (error) {
      setRuntimeMessage('Image analysis failed: $error');
    }
  }

  MobileScannerController buildScannerController() {
    return _scanService.buildScannerController(settings);
  }

  Future<void> handleScan(Barcode barcode) async {
    if (_disposed) return;
    final rawValue = barcode.rawValue?.trim() ?? '';
    if (rawValue.isEmpty) return;
    final (insight, nextHistory) = _scanService.processScan(
      barcode: barcode,
      currentHistory: history,
      historyLimit: settings.historyLimit,
    );
    _history = nextHistory;
    _scanInsight = insight;
    setRuntimeMessage('Scanned ${insight.typeLabel}');
    _ui.tabIndex = 1;
    _safeNotify();
    await _persistenceService.persistHistory(history);
  }

  Future<void> clearHistory() async {
    _history = <ScanRecord>[];
    _safeNotify();
    await _persistenceService.persistHistory(history);
  }

  void restoreHistory(ScanRecord record) {
    _scanInsight = describeScan(record.rawValue, record.codeType);
    _safeNotify();
  }

  Future<void> updateHistoryLimit(int nextLimit) async {
    final (nextSettings, nextHistory) = _settingsService.applyHistoryLimit(
      settings: settings,
      history: history,
      nextLimit: nextLimit,
    );
    _history = nextHistory;
    await updateSetting(nextSettings);
    await _persistenceService.persistHistory(history);
  }

  void setMode(CodeMode nextMode) {
    if (_mode == nextMode) return;
    _mode = nextMode;
    if (_ui.runtimeMessage.isNotEmpty) {
      _ui.runtimeMessage = '';
    }
    _safeNotify();
  }

  void setHeader(String value) {
    _header = value;
    _safeNotify();
  }

  void setFooter(String value) {
    _footer = value;
    _safeNotify();
  }

  void setGeneratorThemeId(String value) {
    _generatorThemeId = value;
    _safeNotify();
  }

  void setFrameId(String value) {
    _frameId = value;
    _safeNotify();
  }

  void setQrStyleId(String value) {
    _qrStyleId = value;
    _safeNotify();
  }

  void setCornerStyleId(String value) {
    _cornerStyleId = value;
    _safeNotify();
  }

  void setQrErrorLevel(String value) {
    _qrErrorLevel = value;
    _safeNotify();
  }

  void setPresetName(String value) {
    _presetName = value;
  }

  Future<List<FileSystemEntity>> loadGalleryEntities() async {
    final dir = await saveDirectory();
    if (!await dir.exists()) return <FileSystemEntity>[];
    final items =
        dir
            .listSync()
            .where((item) => item.path.toLowerCase().endsWith('.png'))
            .toList()
          ..sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
          );
    return items;
  }

  Future<void> deleteGalleryEntity(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    _galleryVersion += 1;
    _safeNotify();
  }

  Future<void> openGalleryEntityInFiles(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type == ResultType.done) return;
    setRuntimeMessage('Open failed: ${result.message}');
  }

  Future<void> shareGalleryEntity(String path) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(path)],
          title: 'Share PNG',
          text: 'Shared from QRCodet',
        ),
      );
      if (result.status == ShareResultStatus.success) {
        setRuntimeMessage('Shared successfully.');
      }
    } catch (error) {
      setRuntimeMessage('Share failed: $error');
    }
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final node in _fieldFocusNodes.values) {
      node.dispose();
    }
    _fieldFocusNodes.clear();
    _cachedMaterialTheme = null;
    _cachedMaterialThemeId = null;
    _cachedPayloadResult = null;
    _cachedPayloadKey = null;
    super.dispose();
  }
}
