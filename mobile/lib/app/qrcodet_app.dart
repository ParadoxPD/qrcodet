import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:barcode_widget/barcode_widget.dart' hide Barcode;
import 'package:custom_qr_generator/custom_qr_generator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zxing_lib/qrcode.dart';

import '../core/data/app_catalog.dart';
import '../core/logic/generator_logic.dart';
import '../core/logic/scan_parser.dart';
import '../core/models/app_models.dart';
import '../core/storage/app_storage.dart';

part 'src/scan_tab.dart';
part 'src/widgets.dart';
part 'features/create/create_tab.dart';
part 'features/gallery/gallery_tab.dart';
part 'features/settings/settings_tab.dart';

const _prefsSettingsKey = 'qrcodet.settings.v1';
const _prefsHistoryKey = 'qrcodet.scan_history.v1';
const _prefsPresetsKey = 'qrcodet.presets.mobile.v1';
class QRCodetApp extends StatefulWidget {
  const QRCodetApp({super.key});

  @override
  State<QRCodetApp> createState() => _QRCodetAppState();
}

class _QRCodetAppState extends State<QRCodetApp> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final ScreenshotController _previewShot = ScreenshotController();
  final ImagePicker _imagePicker = ImagePicker();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm');
  final AppUiState _ui = AppUiState();
  final ScrollPhysics _smoothScroll = const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  late final VoidCallback _uiListener;
  int _lastUiTabIndex = 0;
  bool _lastUiLoading = true;

  late final List<ThemeSpec> _themes = buildThemeSpecs();
  late final List<UseCaseSpec> _qrUseCases = buildQrUseCases();
  late final List<UseCaseSpec> _barcodeUseCases = buildBarcodeUseCases();

  AppSettings _settings = AppSettings.defaults();
  List<ScanRecord> _history = <ScanRecord>[];
  List<GeneratorPreset> _presets = <GeneratorPreset>[];
  CodeMode _mode = CodeMode.qr;
  String _selectedQrId = 'upi';
  String _selectedBarcodeId = 'code128';
  Map<String, Map<String, dynamic>> _valuesMap = <String, Map<String, dynamic>>{};
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

  @override
  void initState() {
    super.initState();
    _lastUiTabIndex = _ui.tabIndex;
    _lastUiLoading = _ui.loading;
    _uiListener = () {
      final tabChanged = _lastUiTabIndex != _ui.tabIndex;
      final loadingChanged = _lastUiLoading != _ui.loading;
      _lastUiTabIndex = _ui.tabIndex;
      _lastUiLoading = _ui.loading;
      if (!mounted || (!tabChanged && !loadingChanged)) return;
      setState(() {});
    };
    _ui.addListener(_uiListener);
    _valuesMap = createInitialValues(_qrUseCases, _barcodeUseCases);
    _loadAppState();
  }

  @override
  void dispose() {
    _ui.removeListener(_uiListener);
    _ui.dispose();
    super.dispose();
  }

  Future<void> _loadAppState() async {
    final prefs = await SharedPreferences.getInstance();
    final rawSettings = prefs.getString(_prefsSettingsKey);
    final rawHistory = prefs.getString(_prefsHistoryKey);
    final rawPresets = prefs.getString(_prefsPresetsKey);
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

    final shouldMigrateSaveDir =
        settings.saveRootPath.isEmpty || settings.saveRootPath.contains('qrcodet_mobile') || settings.saveRootPath.contains('/Android/data/');
    final saveDir = await resolveSaveDirectory(shouldMigrateSaveDir ? '' : settings.saveRootPath);
    if (!mounted) return;
    setState(() {
      _settings = settings.copyWith(saveRootPath: saveDir.path, saveDirectoryPath: saveDir.path);
      _history = history.take(settings.historyLimit).toList();
      _presets = presets;
      _generatorThemeId = settings.generatorThemeId;
      _header = settings.defaultHeader;
      _footer = settings.defaultFooter;
      _frameId = settings.defaultFrameId;
    });
    _ui.setLoading(false);
    await _persistSettings(_settings.copyWith(saveRootPath: saveDir.path, saveDirectoryPath: saveDir.path));
  }

  Future<void> _persistSettings(AppSettings next) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsSettingsKey, jsonEncode(next.toJson()));
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsHistoryKey, jsonEncode(_history.map((e) => e.toJson()).toList()));
  }

  Future<void> _persistPresets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsPresetsKey, jsonEncode(_presets.map((e) => e.toJson()).toList()));
  }

  UseCaseSpec get _selectedUseCase {
    final source = _mode == CodeMode.qr ? _qrUseCases : _barcodeUseCases;
    final selectedId = _mode == CodeMode.qr ? _selectedQrId : _selectedBarcodeId;
    return source.firstWhere((item) => item.id == selectedId);
  }

  ThemeSpec get _activeTheme => _themes.firstWhere((item) => item.id == _generatorThemeId, orElse: () => _themes.first);
  ThemeSpec get _appTheme => _themes.firstWhere((item) => item.id == _settings.appThemeId, orElse: () => _themes.first);
  Color get _appTextColor => _materialTheme.brightness == Brightness.dark ? Colors.white : Colors.black;

  Map<String, dynamic> get _currentValues => _valuesMap['${_mode.name}:${_selectedUseCase.id}'] ?? <String, dynamic>{};

  String get _payload {
    final result = buildPayload(_mode, _selectedUseCase, _currentValues);
    return result.payload;
  }

  String get _payloadError {
    final result = buildPayload(_mode, _selectedUseCase, _currentValues);
    return result.error;
  }

  ThemeData get _materialTheme {
    final spec = _themes.firstWhere((item) => item.id == _settings.appThemeId, orElse: () => _themes.first);
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
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: textColor,
            displayColor: textColor,
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: baseFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brightness == Brightness.dark ? const Color(0xFF322B20) : const Color(0xFFDFD7C9)),
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
        textStyle: TextStyle(
          color: textColor,
        ),
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

  Future<void> _updateSetting(AppSettings next) async {
    setState(() => _settings = next);
    await _persistSettings(next);
  }

  void _runSetState(VoidCallback updates) {
    if (!mounted) return;
    setState(updates);
  }

  void _setField(String fieldName, dynamic value) {
    final key = '${_mode.name}:${_selectedUseCase.id}';
    final next = Map<String, dynamic>.from(_valuesMap[key] ?? <String, dynamic>{});
    next[fieldName] = value;
    setState(() {
      _valuesMap[key] = next;
    });
    _ui.setRuntimeMessage("");
  }

  void _setUseCase(String id) {
    setState(() {
      if (_mode == CodeMode.qr) {
        _selectedQrId = id;
      } else {
        _selectedBarcodeId = id;
      }
      final defaults = _selectedUseCase.defaults;
      _header = defaults['header']?.toString() ?? _header;
      _footer = defaults['footer']?.toString() ?? _footer;
    });
    _ui.setRuntimeMessage("");
  }

  Future<Directory> _saveDirectory() async {
    return resolveSaveDirectory(_settings.saveRootPath);
  }

  Future<void> _saveGeneratedCode() async {
    if (_payload.isEmpty || _payloadError.isNotEmpty) {
      _ui.setRuntimeMessage(_payloadError.isNotEmpty ? _payloadError : 'Fill required fields before saving.');
      return;
    }
    setState(() {
      _saving = true;
    });
    _ui.setRuntimeMessage("");
    try {
      final bytes = await _captureCodePngBytes(_payload);
      if (bytes == null) {
        throw Exception('Preview capture failed.');
      }
      final fileName = '${_selectedUseCase.filenamePrefix}-${DateTime.now().millisecondsSinceEpoch}.png';
      await saveQrToGallery(bytes, fileName);

      final folder = await _saveDirectory();
      final localFile = File('${folder.path}/$fileName');
      await localFile.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      setState(() {
        _lastSavedPath = localFile.path;
      });
      _ui.setRuntimeMessage('Saved to gallery (album: QRCodet) and local cache.');
      _showSaveSuccessNotice(localFile.path, folder.path);
    } on GalException catch (error) {
      _ui.setRuntimeMessage('Save failed: ${error.type.message}');
    } catch (error) {
      _ui.setRuntimeMessage('Save failed: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<Uint8List?> _captureCodePngBytes(String payload) async {
    try {
      final liveBytes = await _previewShot.capture(pixelRatio: 3);
      if (liveBytes != null) return liveBytes;
      await Future<void>.delayed(const Duration(milliseconds: 16));
      return ScreenshotController().captureFromWidget(
        Material(
          color: Colors.transparent,
          child: Theme(
            data: _materialTheme,
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: CodeFrameWidget(
                    frameId: _frameId,
                    theme: _activeTheme,
                    header: _header,
                    footer: _footer,
                    metaLine: payload.isEmpty
                        ? ''
                        : (_currentValues['pn']?.toString() ??
                              _currentValues['name']?.toString() ??
                              _currentValues['url']?.toString() ??
                              _currentValues['value']?.toString() ??
                              ''),
                    child: Container(
                      color: _activeTheme.light,
                      padding: const EdgeInsets.all(14),
                      child: _buildPreviewCode(payload),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        pixelRatio: 3,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickSaveDirectory() async {
    final selected = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select QRCodet save folder');
    if (selected == null || selected.isEmpty) return;
    final dir = await resolveSaveDirectory(selected);
    final next = _settings.copyWith(saveRootPath: dir.path, saveDirectoryPath: dir.path);
    await _updateSetting(next);
    if (!mounted) return;
    _ui.setRuntimeMessage('Default save folder changed to ${dir.path}');
  }

  Future<void> _openSaveFolderAction() async {
    final dir = await _saveDirectory();
    if (!mounted) return;
    _ui.setRuntimeMessage('Active save folder: ${dir.path}');
    final navigatorContext = _navigatorKey.currentContext;
    if (navigatorContext == null) return;
    if (!navigatorContext.mounted) return;
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
                      color: _appTextColor,
                    ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                dir.path,
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      color: _appTextColor,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: dir.path));
                      if (!mounted) return;
                      _showSnackBar(const SnackBar(content: Text('Save folder path copied.')));
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

  void _showSaveSuccessNotice(String filePath, String folderPath) {
    if (!mounted) return;
    _showSnackBar(
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

  void _showSnackBar(SnackBar snackBar) {
    final messenger = _scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(snackBar);
  }

  Future<void> _savePreset() async {
    if (_presetName.trim().isEmpty) return;
    final preset = GeneratorPreset(
      id: 'preset-${DateTime.now().millisecondsSinceEpoch}',
      name: _presetName.trim(),
      mode: _mode.name,
      useCaseId: _selectedUseCase.id,
      values: Map<String, dynamic>.from(_currentValues),
      header: _header,
      footer: _footer,
      themeId: _generatorThemeId,
      frameId: _frameId,
      qrStyleId: _qrStyleId,
      cornerStyleId: _cornerStyleId,
      errorLevel: _qrErrorLevel,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() {
      _presets = <GeneratorPreset>[preset, ..._presets];
      _presetName = '';
    });
    await _persistPresets();
  }

  Future<void> _loadPreset(GeneratorPreset preset) async {
    setState(() {
      _mode = preset.mode == CodeMode.barcode.name ? CodeMode.barcode : CodeMode.qr;
      if (preset.mode == CodeMode.barcode.name) {
        _selectedBarcodeId = preset.useCaseId;
      } else {
        _selectedQrId = preset.useCaseId;
      }
      _valuesMap['${preset.mode}:${preset.useCaseId}'] = Map<String, dynamic>.from(preset.values);
      _header = preset.header;
      _footer = preset.footer;
      _generatorThemeId = preset.themeId;
      _frameId = preset.frameId;
      _qrStyleId = preset.qrStyleId;
      _cornerStyleId = preset.cornerStyleId;
      _qrErrorLevel = preset.errorLevel;
    });
    _ui.setTabIndex(0);
  }

  Future<void> _deletePreset(String id) async {
    setState(() => _presets = _presets.where((item) => item.id != id).toList());
    await _persistPresets();
  }

  Future<void> _analyzeImageFromGallery() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final controller = _buildScannerController();
    try {
      final capture = await controller.analyzeImage(file.path);
      final barcode = capture?.barcodes.isNotEmpty == true ? capture!.barcodes.first : null;
      if (barcode == null) {
        _ui.setRuntimeMessage('No QR or barcode found in the selected image.');
        return;
      }
      await _handleScan(barcode);
    } catch (error) {
      _ui.setRuntimeMessage('Image analysis failed: $error');
    } finally {
      controller.dispose();
    }
  }

  MobileScannerController _buildScannerController() {
    return MobileScannerController(
      autoStart: true,
      facing: _settings.preferFrontCamera ? CameraFacing.front : CameraFacing.back,
      detectionSpeed: _settings.focusProfile == 'fast' ? DetectionSpeed.unrestricted : DetectionSpeed.normal,
      autoZoom: _settings.autoZoom,
      formats: const <BarcodeFormat>[],
      torchEnabled: false,
      initialZoom: _settings.focusProfile == 'macro' ? 0.2 : null,
    );
  }

  Future<void> _handleScan(Barcode barcode) async {
    final rawValue = barcode.rawValue?.trim() ?? '';
    if (rawValue.isEmpty) return;
    final insight = describeScan(rawValue, barcode.format.name);
    final record = ScanRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      rawValue: rawValue,
      codeType: insight.typeLabel,
      title: insight.title,
      scannedAt: DateTime.now().millisecondsSinceEpoch,
    );
    final nextHistory = <ScanRecord>[record, ..._history.where((item) => item.rawValue != rawValue)].take(_settings.historyLimit).toList();
    setState(() {
      _scanInsight = insight;
      _history = nextHistory;
    });
    _ui.setRuntimeMessage('Scanned ${insight.typeLabel}');
    _ui.setTabIndex(1);
    await _persistHistory();
  }

  Future<void> _clearHistory() async {
    setState(() => _history = <ScanRecord>[]);
    await _persistHistory();
  }

  @override
  Widget build(BuildContext context) {
    if (_ui.loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'QRCodet',
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _scaffoldMessengerKey,
        theme: ThemeData.dark(useMaterial3: true),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QRCodet',
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: _materialTheme,
      home: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                _appTheme.accent.withValues(alpha: 0.18),
                _materialTheme.scaffoldBackgroundColor,
                _appTheme.dark.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                  child: AnimatedBuilder(
                    animation: _ui,
                    builder: (context, _) => _Header(theme: _appTheme, runtimeMessage: _ui.runtimeMessage),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildCurrentTab(),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _ui.tabIndex,
          onDestinationSelected: _ui.setTabIndex,
          destinations: const <NavigationDestination>[
            NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Create'),
            NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
            NavigationDestination(icon: Icon(Icons.photo_library_outlined), label: 'Gallery'),
            NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_ui.tabIndex) {
      case 0:
        return KeyedSubtree(key: const ValueKey<String>("tab-create"), child: _buildCreateTab());
      case 1:
        return KeyedSubtree(key: const ValueKey<String>("tab-scan"), child: _buildScanTab());
      case 2:
        return KeyedSubtree(key: const ValueKey<String>("tab-gallery"), child: _buildGalleryTab());
      default:
        return KeyedSubtree(key: const ValueKey<String>("tab-settings"), child: _buildSettingsTab());
    }
  }

  Widget _buildScanTab() {
    return _ScannerTab(
      controllerBuilder: _buildScannerController,
      onDetect: _handleScan,
      onAnalyzeImage: _analyzeImageFromGallery,
      hapticsEnabled: _settings.hapticsEnabled,
      insight: _scanInsight,
      history: _history,
      dateFormat: _dateFormat,
      onRestoreHistory: (record) {
        setState(() => _scanInsight = describeScan(record.rawValue, record.codeType));
      },
    );
  }

}

class AppUiState extends ChangeNotifier {
  bool _loading = true;
  int _tabIndex = 0;
  String _runtimeMessage = '';

  bool get loading => _loading;
  int get tabIndex => _tabIndex;
  String get runtimeMessage => _runtimeMessage;

  void setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }

  void setTabIndex(int value) {
    if (_tabIndex == value) return;
    _tabIndex = value;
    notifyListeners();
  }

  void setRuntimeMessage(String value) {
    if (_runtimeMessage == value) return;
    _runtimeMessage = value;
    notifyListeners();
  }
}
