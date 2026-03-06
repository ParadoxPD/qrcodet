import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:screenshot/screenshot.dart';

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
  AppUiState({this.loading = true, this.tabIndex = 0, this.runtimeMessage = ''});

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
  })  : _persistenceService = persistenceService ?? AppPersistenceService(),
        _createService = createService ?? CreateService(),
        _scanService = scanService ?? ScanService(),
        _settingsService = settingsService ?? SettingsService() {
    valuesMap = createInitialValues(qrUseCases, barcodeUseCases);
  }

  final AppPersistenceService _persistenceService;
  final CreateService _createService;
  final ScanService _scanService;
  final SettingsService _settingsService;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final ScreenshotController previewShot = ScreenshotController();
  final ImagePicker _imagePicker = ImagePicker();
  final DateFormat dateFormat = DateFormat('dd MMM yyyy, HH:mm');
  final Map<String, FocusNode> _fieldFocusNodes = <String, FocusNode>{};

  final List<ThemeSpec> themes = buildThemeSpecs();
  final List<UseCaseSpec> qrUseCases = buildQrUseCases();
  final List<UseCaseSpec> barcodeUseCases = buildBarcodeUseCases();

  final AppUiState ui = AppUiState();
  AppSettings settings = AppSettings.defaults();
  List<ScanRecord> history = <ScanRecord>[];
  List<GeneratorPreset> presets = <GeneratorPreset>[];
  CodeMode mode = CodeMode.qr;
  String selectedQrId = 'upi';
  String selectedBarcodeId = 'code128';
  Map<String, Map<String, dynamic>> valuesMap = <String, Map<String, dynamic>>{};
  String header = 'Scan & Pay';
  String footer = 'Powered by QRCodet';
  String generatorThemeId = 'noir';
  String frameId = 'scan';
  String qrStyleId = 'rounded';
  String cornerStyleId = 'rounded';
  String qrErrorLevel = 'M';
  String lastSavedPath = '';
  String presetName = '';
  ScanInsight? scanInsight;
  bool saving = false;
  bool sharing = false;

  bool _disposed = false;

  ScrollPhysics get smoothScroll {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
      default:
        return const ClampingScrollPhysics();
    }
  }

  UseCaseSpec get selectedUseCase {
    final source = mode == CodeMode.qr ? qrUseCases : barcodeUseCases;
    final selectedId = mode == CodeMode.qr ? selectedQrId : selectedBarcodeId;
    return source.firstWhere((item) => item.id == selectedId);
  }

  ThemeSpec get activeTheme => themes.firstWhere((item) => item.id == generatorThemeId, orElse: () => themes.first);
  ThemeSpec get appTheme => themes.firstWhere((item) => item.id == settings.appThemeId, orElse: () => themes.first);

  ThemeData get materialTheme {
    final spec = themes.firstWhere((item) => item.id == settings.appThemeId, orElse: () => themes.first);
    final brightness = spec.mood == ThemeMood.dark ? Brightness.dark : Brightness.light;
    final scheme = ColorScheme.fromSeed(seedColor: spec.accent, brightness: brightness).copyWith(
      primary: spec.accent,
      secondary: spec.dark,
      surface: spec.light,
      onSurface: brightness == Brightness.dark ? Colors.white : Colors.black,
      onSurfaceVariant: brightness == Brightness.dark ? Colors.white : Colors.black,
    );
    final textColor = brightness == Brightness.dark ? Colors.white : Colors.black;
    final baseFill = brightness == Brightness.dark ? const Color(0xFF1A1712) : Colors.white;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      canvasColor: brightness == Brightness.dark ? const Color(0xFF1A1712) : Colors.white,
      scaffoldBackgroundColor: brightness == Brightness.dark ? const Color(0xFF0E0D0A) : const Color(0xFFF5F1E7),
      cardTheme: CardThemeData(
        elevation: 0,
        color: brightness == Brightness.dark ? const Color(0xFF171510) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(bodyColor: textColor, displayColor: textColor),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: baseFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: brightness == Brightness.dark ? const Color(0xFF322B20) : const Color(0xFFDFD7C9),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: spec.accent.withValues(alpha: brightness == Brightness.dark ? 0.28 : 0.2),
        backgroundColor: brightness == Brightness.dark ? const Color(0xFF14110D) : const Color(0xFFF8F4EA),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: brightness == Brightness.dark ? const Color(0xFF1A1712) : Colors.white,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: brightness == Brightness.dark ? const Color(0xFF1A1712) : Colors.white,
        textStyle: TextStyle(color: textColor),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: brightness == Brightness.dark ? const Color(0xFFF0EAD9) : const Color(0xFF1B1812),
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: TextStyle(
          color: brightness == Brightness.dark ? const Color(0xFF1B1812) : const Color(0xFFF0EAD9),
          fontSize: 12,
        ),
        waitDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  Color get appTextColor => materialTheme.brightness == Brightness.dark ? Colors.white : Colors.black;

  Map<String, dynamic> get currentValues => valuesMap['${mode.name}:${selectedUseCase.id}'] ?? <String, dynamic>{};

  String get payload => buildPayload(mode, selectedUseCase, currentValues).payload;

  String get payloadError => buildPayload(mode, selectedUseCase, currentValues).error;

  Future<void> initialize() async {
    final loaded = await _persistenceService.load();
    final shouldMigrateSaveDir = loaded.settings.saveRootPath.isEmpty ||
        loaded.settings.saveRootPath.contains('qrcodet_mobile') ||
        loaded.settings.saveRootPath.contains('/Android/data/');
    final saveDir = await resolveSaveDirectory(shouldMigrateSaveDir ? '' : loaded.settings.saveRootPath);

    settings = loaded.settings.copyWith(saveRootPath: saveDir.path, saveDirectoryPath: saveDir.path);
    history = loaded.history.take(loaded.settings.historyLimit).toList();
    presets = loaded.presets;
    generatorThemeId = settings.generatorThemeId;
    header = settings.defaultHeader;
    footer = settings.defaultFooter;
    frameId = settings.defaultFrameId;
    ui.loading = false;
    _safeNotify();

    await _persistenceService.persistSettings(settings.copyWith(saveRootPath: saveDir.path, saveDirectoryPath: saveDir.path));
  }

  void setTabIndex(int value) {
    if (ui.tabIndex == value) return;
    ui.tabIndex = value;
    _safeNotify();
  }

  void setRuntimeMessage(String value) {
    if (ui.runtimeMessage == value) return;
    ui.runtimeMessage = value;
    _safeNotify();
  }

  Future<void> updateSetting(AppSettings next) async {
    settings = next;
    _safeNotify();
    await _persistenceService.persistSettings(next);
  }

  void runSetState(VoidCallback updates) {
    updates();
    _safeNotify();
  }

  void setField(String fieldName, dynamic value) {
    final key = '${mode.name}:${selectedUseCase.id}';
    final next = Map<String, dynamic>.from(valuesMap[key] ?? <String, dynamic>{});
    next[fieldName] = value;
    valuesMap[key] = next;
    setRuntimeMessage('');
  }

  void setUseCase(String id) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (mode == CodeMode.qr) {
      selectedQrId = id;
    } else {
      selectedBarcodeId = id;
    }
    final defaults = selectedUseCase.defaults;
    header = defaults['header']?.toString() ?? header;
    footer = defaults['footer']?.toString() ?? footer;
    setRuntimeMessage('');
    _safeNotify();
  }

  Future<Directory> saveDirectory() async {
    return resolveSaveDirectory(settings.saveRootPath);
  }

  Future<void> saveGeneratedCode({required Future<Uint8List?> Function() captureBytes}) async {
    if (payload.isEmpty || payloadError.isNotEmpty) {
      focusFirstMissingRequiredField();
      setRuntimeMessage(payloadError.isNotEmpty ? payloadError : 'Fill required fields before saving.');
      return;
    }
    saving = true;
    setRuntimeMessage('');
    _safeNotify();
    try {
      final result = await _createService.saveGeneratedCode(
        payload: payload,
        payloadError: payloadError,
        captureBytes: captureBytes,
        selectedUseCase: selectedUseCase,
        saveDirectory: saveDirectory,
      );
      if (result.savedPath != null && result.folderPath != null) {
        lastSavedPath = result.savedPath!;
        showSaveSuccessNotice(result.savedPath!, result.folderPath!);
      }
      setRuntimeMessage(result.message);
      _safeNotify();
    } finally {
      saving = false;
      _safeNotify();
    }
  }

  Future<void> shareGeneratedCode({required Future<Uint8List?> Function() captureBytes}) async {
    if (payload.isEmpty || payloadError.isNotEmpty) {
      focusFirstMissingRequiredField();
      setRuntimeMessage(payloadError.isNotEmpty ? payloadError : 'Fill required fields before sharing.');
      return;
    }
    sharing = true;
    setRuntimeMessage('');
    _safeNotify();
    try {
      final result = await _createService.shareGeneratedCode(
        payload: payload,
        payloadError: payloadError,
        captureBytes: captureBytes,
        selectedUseCase: selectedUseCase,
      );
      setRuntimeMessage(result.message);
    } finally {
      sharing = false;
      _safeNotify();
    }
  }

  FocusNode focusNodeForField(String fieldName) {
    final key = '${mode.name}:${selectedUseCase.id}:$fieldName';
    return _fieldFocusNodes.putIfAbsent(key, () => FocusNode(debugLabel: key));
  }

  void focusFirstMissingRequiredField() {
    for (final field in selectedUseCase.fields.where((item) => item.required)) {
      final value = currentValues[field.name];
      final missing = value == null || (value is String && value.trim().isEmpty);
      if (!missing) continue;
      focusNodeForField(field.name).requestFocus();
      return;
    }
  }

  Future<void> pickSaveDirectory() async {
    final dir = await _settingsService.pickSaveDirectory();
    if (dir == null) return;
    final next = settings.copyWith(saveRootPath: dir.path, saveDirectoryPath: dir.path);
    await updateSetting(next);
    setRuntimeMessage('Default save folder changed to ${dir.path}');
  }

  Future<void> openSaveFolderAction() async {
    final dir = await saveDirectory();
    setRuntimeMessage('Active save folder: ${dir.path}');
    final navigatorContext = navigatorKey.currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) return;
    await showModalBottomSheet<void>(
      context: navigatorContext,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Active Save Folder',
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: appTextColor,
                    ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                dir.path,
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      color: appTextColor,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: dir.path));
                      showSnackBar(const SnackBar(content: Text('Save folder path copied.')));
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy Path'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
    presets = <GeneratorPreset>[preset, ...presets];
    presetName = '';
    _safeNotify();
    await _persistenceService.persistPresets(presets);
  }

  Future<void> loadPreset(GeneratorPreset preset) async {
    mode = preset.mode == CodeMode.barcode.name ? CodeMode.barcode : CodeMode.qr;
    if (preset.mode == CodeMode.barcode.name) {
      selectedBarcodeId = preset.useCaseId;
    } else {
      selectedQrId = preset.useCaseId;
    }
    valuesMap['${preset.mode}:${preset.useCaseId}'] = Map<String, dynamic>.from(preset.values);
    header = preset.header;
    footer = preset.footer;
    generatorThemeId = preset.themeId;
    frameId = preset.frameId;
    qrStyleId = preset.qrStyleId;
    cornerStyleId = preset.cornerStyleId;
    qrErrorLevel = preset.errorLevel;
    ui.tabIndex = 0;
    _safeNotify();
  }

  Future<void> deletePreset(String id) async {
    presets = presets.where((item) => item.id != id).toList();
    _safeNotify();
    await _persistenceService.persistPresets(presets);
  }

  Future<void> analyzeImageFromGallery() async {
    final barcode = await _scanService.analyzeImageFromGallery(
      imagePicker: _imagePicker,
      controllerBuilder: buildScannerController,
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
    final rawValue = barcode.rawValue?.trim() ?? '';
    if (rawValue.isEmpty) return;
    final (insight, nextHistory) = _scanService.processScan(
      barcode: barcode,
      currentHistory: history,
      historyLimit: settings.historyLimit,
    );
    history = nextHistory;
    scanInsight = insight;
    setRuntimeMessage('Scanned ${insight.typeLabel}');
    ui.tabIndex = 1;
    _safeNotify();
    await _persistenceService.persistHistory(history);
  }

  Future<void> clearHistory() async {
    history = <ScanRecord>[];
    _safeNotify();
    await _persistenceService.persistHistory(history);
  }

  void restoreHistory(ScanRecord record) {
    scanInsight = describeScan(record.rawValue, record.codeType);
    _safeNotify();
  }

  Future<void> updateHistoryLimit(int nextLimit) async {
    final (nextSettings, nextHistory) = _settingsService.applyHistoryLimit(
      settings: settings,
      history: history,
      nextLimit: nextLimit,
    );
    history = nextHistory;
    await updateSetting(nextSettings);
    await _persistenceService.persistHistory(history);
  }

  void setMode(CodeMode nextMode) {
    if (mode == nextMode) return;
    mode = nextMode;
    setRuntimeMessage('');
    _safeNotify();
  }

  void setHeader(String value) {
    header = value;
    _safeNotify();
  }

  void setFooter(String value) {
    footer = value;
    _safeNotify();
  }

  void setGeneratorThemeId(String value) {
    generatorThemeId = value;
    _safeNotify();
  }

  void setFrameId(String value) {
    frameId = value;
    _safeNotify();
  }

  void setQrStyleId(String value) {
    qrStyleId = value;
    _safeNotify();
  }

  void setCornerStyleId(String value) {
    cornerStyleId = value;
    _safeNotify();
  }

  void setQrErrorLevel(String value) {
    qrErrorLevel = value;
    _safeNotify();
  }

  void setPresetName(String value) {
    presetName = value;
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
    super.dispose();
  }
}
