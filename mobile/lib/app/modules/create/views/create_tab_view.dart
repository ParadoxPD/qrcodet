import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:barcode_widget/barcode_widget.dart' hide Barcode;
import 'package:custom_qr_generator/custom_qr_generator.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:zxing_lib/qrcode.dart';

import '../../../../core/data/app_catalog.dart';
import '../../../../core/logic/generator_logic.dart';
import '../../../../core/models/app_models.dart';
import '../../../providers/qrcodet_provider.dart';
import '../../../views/widgets/app_widgets.dart';

class CreateTabView extends StatelessWidget {
  const CreateTabView({super.key, required this.vm});

  final CreateProvider vm;

  @override
  Widget build(BuildContext context) {
    final payload = _payload;
    final error = _payloadError;
    final useCases = _mode == CodeMode.qr ? _qrUseCases : _barcodeUseCases;
    final values = _currentValues;
    final hasCode = payload.isNotEmpty && error.isEmpty;
    final cardBase = Theme.of(context).cardColor;
    final cardTextColor =
        ThemeData.estimateBrightnessForColor(cardBase) == Brightness.dark
        ? Colors.black
        : Colors.white;
    final payloadBase = _materialTheme.colorScheme.surfaceContainerHighest
        .withValues(alpha: 0.5);
    final payloadTextColor =
        ThemeData.estimateBrightnessForColor(payloadBase) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: ListView(
        physics: _smoothScroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const AppSectionTitle(
                  kicker: 'Mode',
                  title: 'Choose your code type',
                ),
                const SizedBox(height: 12),
                SegmentedButton<CodeMode>(
                  segments: const <ButtonSegment<CodeMode>>[
                    ButtonSegment<CodeMode>(
                      value: CodeMode.qr,
                      label: Text('QR Codes'),
                      icon: Icon(Icons.grid_view_rounded),
                    ),
                    ButtonSegment<CodeMode>(
                      value: CodeMode.barcode,
                      label: Text('Barcodes'),
                      icon: Icon(Icons.view_stream_rounded),
                    ),
                  ],
                  selected: <CodeMode>{_mode},
                  onSelectionChanged: (selection) {
                    _runSetState(() {
                      _mode = selection.first;
                    });
                    _ui.setRuntimeMessage('');
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>('usecase-${_selectedUseCase.id}'),
                  initialValue: _selectedUseCase.id,
                  decoration: const InputDecoration(
                    labelText: 'Use case',
                    border: OutlineInputBorder(),
                  ),
                  items: useCases
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Tooltip(
                            message: item.description,
                            textStyle: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF1B1812)
                                      : const Color(0xFFF0EAD9),
                                ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFFF0EAD9)
                                  : const Color(0xFF1B1812),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) _setUseCase(value);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const AppSectionTitle(
                  kicker: 'Data',
                  title: 'Fill the payload fields',
                ),
                const SizedBox(height: 12),
                ..._selectedUseCase.fields.map(
                  (field) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildField(field, values[field.name]),
                  ),
                ),
                if (error.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      error,
                      style: TextStyle(color: Colors.red.shade300),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const AppSectionTitle(
                  kicker: 'Style',
                  title: 'Tune the frame and theme',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _header,
                  decoration: const InputDecoration(
                    labelText: 'Header',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _runSetState(() => _header = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _footer,
                  decoration: const InputDecoration(
                    labelText: 'Footer',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _runSetState(() => _footer = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>('theme-$_generatorThemeId'),
                  initialValue: _generatorThemeId,
                  decoration: const InputDecoration(
                    labelText: 'Theme',
                    border: OutlineInputBorder(),
                  ),
                  items: _themes
                      .map(
                        (theme) => DropdownMenuItem<String>(
                          value: theme.id,
                          child: Text(theme.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => _runSetState(
                    () => _generatorThemeId = value ?? _generatorThemeId,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>('frame-$_frameId'),
                  initialValue: _frameId,
                  decoration: const InputDecoration(
                    labelText: 'Frame',
                    border: OutlineInputBorder(),
                  ),
                  items: frameLabels.entries
                      .map(
                        (entry) => DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      _runSetState(() => _frameId = value ?? _frameId),
                ),
                if (_mode == CodeMode.qr) ...<Widget>[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>('qrstyle-$_qrStyleId'),
                    initialValue: _qrStyleId,
                    decoration: const InputDecoration(
                      labelText: 'QR dot style',
                      border: OutlineInputBorder(),
                    ),
                    items: qrStyleLabels.entries
                        .map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        _runSetState(() => _qrStyleId = value ?? _qrStyleId),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>('corner-$_cornerStyleId'),
                    initialValue: _cornerStyleId,
                    decoration: const InputDecoration(
                      labelText: 'Corner style',
                      border: OutlineInputBorder(),
                    ),
                    items: cornerStyleLabels.entries
                        .map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => _runSetState(
                      () => _cornerStyleId = value ?? _cornerStyleId,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>('error-$_qrErrorLevel'),
                    initialValue: _qrErrorLevel,
                    decoration: const InputDecoration(
                      labelText: 'Error correction',
                      border: OutlineInputBorder(),
                    ),
                    items: const <String>['L', 'M', 'Q', 'H']
                        .map(
                          (level) => DropdownMenuItem<String>(
                            value: level,
                            child: Text(level),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => _runSetState(
                      () => _qrErrorLevel = value ?? _qrErrorLevel,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const AppSectionTitle(
                  kicker: 'Preview',
                  title: 'Live preview and export',
                ),
                const SizedBox(height: 12),
                Screenshot(
                  controller: _previewShot,
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
                      child: Center(
                        child: hasCode
                            ? _buildPreviewCode(payload)
                            : const Text('Fill required fields to generate'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: (_saving || _sharing) ? null : _saveGeneratedCode,
                        icon: const Icon(Icons.download_rounded),
                        label: Text(_saving ? 'Saving...' : 'Save PNG'),
                      ),
                      OutlinedButton.icon(
                        onPressed: (_saving || _sharing) ? null : _shareGeneratedCode,
                        icon: const Icon(Icons.share_rounded),
                        label: Text(_sharing ? 'Sharing...' : 'Share PNG'),
                      ),
                    ],
                  ),
                if (_lastSavedPath.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    'Last save: $_lastSavedPath',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cardTextColor),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Encoded payload',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: cardTextColor),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _materialTheme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SelectableText(
                    payload.isEmpty ? 'Nothing encoded yet.' : payload,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: payloadTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const AppSectionTitle(
                  kicker: 'Presets',
                  title: 'Reusable mobile presets',
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Preset name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _presetName = value,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _savePreset,
                      child: const Text('Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_presets.isEmpty)
                  const Text('No presets yet.')
                else
                  ..._presets
                      .take(8)
                      .map(
                        (preset) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(preset.name),
                          subtitle: Text(
                            '${preset.mode.toUpperCase()} / ${preset.useCaseId}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                onPressed: () => _loadPreset(preset),
                                icon: const Icon(Icons.upload_rounded),
                              ),
                              IconButton(
                                onPressed: () => _deletePreset(preset.id),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  CreateProvider get _ui => vm;
  CodeMode get _mode => vm.mode;
  set _mode(CodeMode value) => vm.mode = value;
  List<UseCaseSpec> get _qrUseCases => vm.qrUseCases;
  List<UseCaseSpec> get _barcodeUseCases => vm.barcodeUseCases;
  Map<String, dynamic> get _currentValues => vm.currentValues;
  UseCaseSpec get _selectedUseCase => vm.selectedUseCase;
  ThemeData get _materialTheme => vm.materialTheme;
  ThemeSpec get _activeTheme => vm.activeTheme;
  List<ThemeSpec> get _themes => vm.themes;
  String get _payload => vm.payload;
  String get _payloadError => vm.payloadError;
  String get _header => vm.header;
  set _header(String value) => vm.header = value;
  String get _footer => vm.footer;
  set _footer(String value) => vm.footer = value;
  String get _generatorThemeId => vm.generatorThemeId;
  set _generatorThemeId(String value) => vm.generatorThemeId = value;
  String get _frameId => vm.frameId;
  set _frameId(String value) => vm.frameId = value;
  String get _qrStyleId => vm.qrStyleId;
  set _qrStyleId(String value) => vm.qrStyleId = value;
  String get _cornerStyleId => vm.cornerStyleId;
  set _cornerStyleId(String value) => vm.cornerStyleId = value;
  String get _qrErrorLevel => vm.qrErrorLevel;
  set _qrErrorLevel(String value) => vm.qrErrorLevel = value;
  bool get _saving => vm.saving;
  bool get _sharing => vm.sharing;
  String get _lastSavedPath => vm.lastSavedPath;
  set _presetName(String value) => vm.presetName = value;
  List<GeneratorPreset> get _presets => vm.presets;
  ScrollPhysics get _smoothScroll => vm.smoothScroll;
  ScreenshotController get _previewShot => vm.previewShot;

  void _runSetState(VoidCallback updates) => vm.runSetState(updates);
  void _setUseCase(String id) => vm.setUseCase(id);
  void _setField(String fieldName, dynamic value) => vm.setField(fieldName, value);
  FocusNode _focusNodeForField(String fieldName) => vm.focusNodeForField(fieldName);
  Future<void> _savePreset() => vm.savePreset();
  Future<void> _loadPreset(GeneratorPreset preset) => vm.loadPreset(preset);
  Future<void> _deletePreset(String id) => vm.deletePreset(id);

  Future<void> _saveGeneratedCode() async {
    await vm.saveGeneratedCode(captureBytes: () => _captureCodePngBytes(_payload));
  }

  Future<void> _shareGeneratedCode() async {
    await vm.shareGeneratedCode(captureBytes: () => _captureCodePngBytes(_payload));
  }

  Future<Uint8List?> _captureCodePngBytes(String payload) async {
    try {
      final liveBytes = await vm.previewShot.capture(pixelRatio: 3);
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

  Widget _buildField(FieldSpec field, dynamic value) {
    final current = value ?? field.defaultValue;
    final requiredLabel = _fieldLabel(field);
    switch (field.kind) {
      case FieldKind.select:
        return DropdownButtonFormField<String>(
          key: ValueKey<String>(
            'field-${field.name}-${current?.toString() ?? field.options.first}',
          ),
          initialValue: (current?.toString().isNotEmpty == true
              ? current.toString()
              : field.options.first),
          decoration: InputDecoration(
            label: requiredLabel,
            border: const OutlineInputBorder(),
            helperText: field.helperText,
          ),
          items: field.options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(),
          onChanged: (next) => _setField(field.name, next ?? ''),
        );
      case FieldKind.checkbox:
        return SwitchListTile.adaptive(
          title: requiredLabel,
          subtitle: Text(field.helperText),
          value: current == true,
          onChanged: (next) => _setField(field.name, next),
          contentPadding: EdgeInsets.zero,
        );
      default:
        return TextFormField(
          focusNode: _focusNodeForField(field.name),
          initialValue: current?.toString() ?? '',
          keyboardType: field.kind == FieldKind.number
              ? const TextInputType.numberWithOptions(decimal: true)
              : field.kind == FieldKind.datetime
              ? TextInputType.datetime
              : TextInputType.text,
          maxLines:
              field.name == 'body' ||
                  field.name == 'text' ||
                  field.name == 'description'
              ? 3
              : 1,
          decoration: InputDecoration(
            label: requiredLabel,
            border: const OutlineInputBorder(),
            hintText: field.placeholder,
            helperText: field.helperText,
          ),
          onChanged: (next) => _setField(field.name, next),
        );
    }
  }

  Widget _fieldLabel(FieldSpec field) {
    if (!field.required) return Text(field.label);
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: field.label),
          const TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCode(String payload) {
    if (_mode == CodeMode.qr) {
      if (_needsWebLikePainter(_qrStyleId, _cornerStyleId)) {
        return CustomPaint(
          size: const Size.square(250),
          painter: _WebLikeQrPainter(
            data: payload,
            ecl: toQrErrorLevel(_qrErrorLevel),
            dotStyleId: _qrStyleId,
            cornerStyleId: _cornerStyleId,
            darkColor: _activeTheme.dark,
            accentColor: _activeTheme.accent,
            backgroundColor: _activeTheme.light,
          ),
        );
      }
      final shapeSet = _qrShapeSet(_qrStyleId, _cornerStyleId);
      return CustomPaint(
        size: const Size.square(250),
        painter: QrPainter(
          data: payload,
          options: QrOptions(
            padding: 0.14,
            ecl: toQrErrorLevel(_qrErrorLevel),
            colors: QrColors(
              dark: QrColorSolid(_activeTheme.dark),
              frame: QrColorSolid(_activeTheme.dark),
              ball: QrColorSolid(_activeTheme.accent),
              background: QrColorSolid(_activeTheme.light),
            ),
            shapes: QrShapes(
              darkPixel: shapeSet.$1,
              frame: shapeSet.$2,
              ball: shapeSet.$3,
            ),
          ),
        ),
      );
    }

    final barcode = barcodeFactoryFor(_selectedUseCase.id);
    final square = isSquareBarcode(_selectedUseCase.id);
    return BarcodeWidget(
      barcode: barcode,
      data: payload,
      width: square ? 230 : 320,
      height: square ? 230 : 120,
      drawText: !square,
      color: _activeTheme.dark,
      backgroundColor: _activeTheme.light,
    );
  }

  bool _needsWebLikePainter(String dotStyleId, String cornerStyleId) {
    const unsupportedDots = <String>{
      'diamond',
      'kite',
      'plus',
      'star',
      'cross',
      'bars_v',
    };
    return unsupportedDots.contains(dotStyleId) || cornerStyleId == 'diamond';
  }

  (QrPixelShape, QrFrameShape, QrBallShape) _qrShapeSet(
    String dotStyleId,
    String cornerStyleId,
  ) {
    // Best-effort mapping to web styles using shapes supported by custom_qr_generator.
    final pixel = switch (dotStyleId) {
      'square' => const QrPixelShapeDefault(),
      'rounded' => const QrPixelShapeRoundCorners(cornerFraction: 0.28),
      'dot' => const QrPixelShapeCircle(radiusFraction: 0.8),
      'diamond' => const QrPixelShapeRoundCorners(cornerFraction: 0.06),
      'squircle' => const QrPixelShapeRoundCorners(cornerFraction: 0.42),
      'kite' => const QrPixelShapeRoundCorners(cornerFraction: 0.18),
      'plus' => const QrPixelShapeRoundCorners(cornerFraction: 0.04),
      'star' => const QrPixelShapeCircle(radiusFraction: 0.62),
      'cross' => const QrPixelShapeCircle(radiusFraction: 0.74),
      'bars_v' => const QrPixelShapeRoundCorners(cornerFraction: 0.0),
      _ => const QrPixelShapeDefault(),
    };

    final (QrFrameShape frame, QrBallShape ball) = switch (cornerStyleId) {
      'square' => (const QrFrameShapeDefault(), const QrBallShapeDefault()),
      'rounded' => (
        const QrFrameShapeRoundCorners(cornerFraction: 0.2, widthFraction: 1),
        const QrBallShapeRoundCorners(cornerFraction: 0.2),
      ),
      'dot' => (
        const QrFrameShapeCircle(widthFraction: 1, radiusFraction: 1),
        const QrBallShapeCircle(radiusFraction: 1),
      ),
      'diamond' => (
        const QrFrameShapeRoundCorners(cornerFraction: 0.1, widthFraction: 1),
        const QrBallShapeRoundCorners(cornerFraction: 0.1),
      ),
      'leaf' => (
        const QrFrameShapeRoundCorners(
          cornerFraction: 0.44,
          widthFraction: 1,
          topLeft: true,
          topRight: true,
          bottomLeft: true,
          bottomRight: true,
        ),
        const QrBallShapeRoundCorners(cornerFraction: 0.42),
      ),
      _ => (const QrFrameShapeDefault(), const QrBallShapeDefault()),
    };

    return (pixel, frame, ball);
  }
}

class _WebLikeQrPainter extends CustomPainter {
  _WebLikeQrPainter({
    required this.data,
    required this.ecl,
    required this.dotStyleId,
    required this.cornerStyleId,
    required this.darkColor,
    required this.accentColor,
    required this.backgroundColor,
  }) {
    _matrix = Encoder.encode(data, ecl).matrix!;
  }

  final String data;
  final ErrorCorrectionLevel ecl;
  final String dotStyleId;
  final String cornerStyleId;
  final Color darkColor;
  final Color accentColor;
  final Color backgroundColor;
  late final dynamic _matrix;

  bool _inFinder(int row, int col, int count) {
    final topLeft = row < 7 && col < 7;
    final topRight = row < 7 && col >= count - 7;
    final bottomLeft = row >= count - 7 && col < 7;
    return topLeft || topRight || bottomLeft;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final codeSize = math.min(size.width, size.height);
    const padRatio = 0.14;
    final padding = codeSize * padRatio;
    final count = _matrix.width;
    final module = (codeSize - (padding * 2)) / count;
    final offset = Offset(
      (size.width - codeSize) / 2 + padding,
      (size.height - codeSize) / 2 + padding,
    );

    final bg = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, bg);

    final dark = Paint()..color = darkColor;
    final light = Paint()..color = backgroundColor;
    final accent = Paint()..color = accentColor;

    for (var row = 0; row < count; row += 1) {
      for (var col = 0; col < count; col += 1) {
        if (_matrix.get(col, row) != 1) continue;
        if (_inFinder(row, col, count)) continue;
        final x = offset.dx + (col * module);
        final y = offset.dy + (row * module);
        _drawDot(canvas, Rect.fromLTWH(x, y, module, module), dotStyleId, dark);
      }
    }

    _drawFinder(canvas, offset, module, cornerStyleId, dark, light, accent);
    _drawFinder(
      canvas,
      Offset(offset.dx + ((count - 7) * module), offset.dy),
      module,
      cornerStyleId,
      dark,
      light,
      accent,
    );
    _drawFinder(
      canvas,
      Offset(offset.dx, offset.dy + ((count - 7) * module)),
      module,
      cornerStyleId,
      dark,
      light,
      accent,
    );
  }

  void _drawFinder(
    Canvas canvas,
    Offset topLeft,
    double module,
    String style,
    Paint dark,
    Paint light,
    Paint accent,
  ) {
    final outer = Rect.fromLTWH(topLeft.dx, topLeft.dy, module * 7, module * 7);
    final inner = Rect.fromLTWH(
      topLeft.dx + module,
      topLeft.dy + module,
      module * 5,
      module * 5,
    );
    final core = Rect.fromLTWH(
      topLeft.dx + (module * 2),
      topLeft.dy + (module * 2),
      module * 3,
      module * 3,
    );
    _drawFinderShape(canvas, outer, style, dark);
    _drawFinderShape(canvas, inner, style, light);
    _drawFinderShape(canvas, core, style, accent);
  }

  void _drawFinderShape(Canvas canvas, Rect r, String style, Paint paint) {
    switch (style) {
      case 'dot':
        canvas.drawOval(r, paint);
        return;
      case 'diamond':
        final cx = r.center.dx;
        final cy = r.center.dy;
        final path = Path()
          ..moveTo(cx, r.top)
          ..lineTo(r.right, cy)
          ..lineTo(cx, r.bottom)
          ..lineTo(r.left, cy)
          ..close();
        canvas.drawPath(path, paint);
        return;
      case 'leaf':
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            r,
            topLeft: Radius.circular(r.width * 0.44),
            topRight: Radius.circular(r.width * 0.44),
            bottomLeft: Radius.circular(r.width * 0.12),
            bottomRight: Radius.circular(r.width * 0.12),
          ),
          paint,
        );
        return;
      case 'rounded':
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.2)),
          paint,
        );
        return;
      default:
        canvas.drawRect(r, paint);
    }
  }

  void _drawDot(Canvas canvas, Rect r, String style, Paint paint) {
    final cx = r.center.dx;
    final cy = r.center.dy;
    final size = r.width;
    switch (style) {
      case 'dot':
        canvas.drawCircle(Offset(cx, cy), size * 0.4, paint);
        return;
      case 'rounded':
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, Radius.circular(size * 0.28)),
          paint,
        );
        return;
      case 'diamond':
      case 'kite':
        final h = (size / 2) * 0.92;
        final k = style == 'kite' ? 0.86 : 1.0;
        final path = Path()
          ..moveTo(cx, cy - h)
          ..lineTo(cx + (h * k), cy)
          ..lineTo(cx, cy + h)
          ..lineTo(cx - (h * k), cy)
          ..close();
        canvas.drawPath(path, paint);
        return;
      case 'squircle':
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, Radius.circular(size * 0.42)),
          paint,
        );
        return;
      case 'plus':
      case 'cross':
        final width = size * 0.24;
        final arm = size * 0.36;
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: width,
            height: arm * 2,
          ),
          paint,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: arm * 2,
            height: width,
          ),
          paint,
        );
        return;
      case 'star':
        final outer = (size / 2) * 0.94;
        final inner = outer * 0.44;
        final path = Path();
        for (var i = 0; i < 10; i += 1) {
          final radius = i.isEven ? outer : inner;
          final angle = ((math.pi / 5) * i) - (math.pi / 2);
          final px = cx + (radius * math.cos(angle));
          final py = cy + (radius * math.sin(angle));
          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        return;
      case 'bars_v':
        final bar = size * 0.34;
        canvas.drawRect(Rect.fromLTWH(cx - bar - 1, r.top, bar, size), paint);
        canvas.drawRect(Rect.fromLTWH(cx + 1, r.top, bar, size), paint);
        return;
      default:
        canvas.drawRect(r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WebLikeQrPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.ecl != ecl ||
        oldDelegate.dotStyleId != dotStyleId ||
        oldDelegate.cornerStyleId != cornerStyleId ||
        oldDelegate.darkColor != darkColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
