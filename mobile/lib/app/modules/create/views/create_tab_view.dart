import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:barcode_widget/barcode_widget.dart' hide Barcode;
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

import '../../../../core/logic/generator_logic.dart';
import '../../../../core/models/app_models.dart';
import '../../../providers/qrcodet_provider.dart';
import '../../../views/widgets/app_widgets.dart';
import 'widgets/create_form_section.dart';
import 'widgets/create_preset_section.dart';
import 'widgets/create_preview_section.dart';
import 'widgets/create_style_section.dart';
import 'widgets/qr_preview_renderer.dart';

class CreateTabView extends StatelessWidget {
  const CreateTabView({super.key, required this.vm});

  final CreateProvider vm;
  static final ScreenshotController _fallbackController =
      ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final payload = vm.payload;
    final error = vm.payloadError;
    final useCases = vm.mode == CodeMode.qr
        ? vm.qrUseCases
        : vm.barcodeUseCases;
    final values = vm.currentValues;
    final hasCode = payload.isNotEmpty && error.isEmpty;

    return ListView(
      physics: vm.smoothScroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: <Widget>[
        CreateFormSection(
          mode: vm.mode,
          useCases: useCases,
          selectedUseCase: vm.selectedUseCase,
          values: values,
          onModeChanged: (nextMode) {
            vm.mode = nextMode;
            vm.setRuntimeMessage('');
          },
          onUseCaseChanged: vm.setUseCase,
          buildField: (field, value) => _buildField(vm, field, value),
          error: error,
        ),
        const SizedBox(height: 12),
        CreateStyleSection(
          mode: vm.mode,
          header: vm.header,
          footer: vm.footer,
          generatorThemeId: vm.generatorThemeId,
          frameId: vm.frameId,
          qrStyleId: vm.qrStyleId,
          cornerStyleId: vm.cornerStyleId,
          qrErrorLevel: vm.qrErrorLevel,
          themes: vm.themes,
          onHeaderChanged: (value) => vm.header = value,
          onFooterChanged: (value) => vm.footer = value,
          onGeneratorThemeChanged: (value) => vm.generatorThemeId = value,
          onFrameChanged: (value) => vm.frameId = value,
          onQrStyleChanged: (value) => vm.qrStyleId = value,
          onCornerStyleChanged: (value) => vm.cornerStyleId = value,
          onErrorLevelChanged: (value) => vm.qrErrorLevel = value,
        ),
        const SizedBox(height: 12),
        CreatePreviewSection(
          previewController: vm.previewShot,
          mode: vm.mode,
          barcodeUseCaseId: vm.selectedUseCase.id,
          frameId: vm.frameId,
          theme: vm.activeTheme,
          header: vm.header,
          footer: vm.footer,
          metaLine: payload.isEmpty
              ? ''
              : (vm.currentValues['pn']?.toString() ??
                    vm.currentValues['name']?.toString() ??
                    vm.currentValues['url']?.toString() ??
                    vm.currentValues['value']?.toString() ??
                    ''),
          payload: payload,
          qrStyleId: vm.qrStyleId,
          cornerStyleId: vm.cornerStyleId,
          qrErrorLevel: vm.qrErrorLevel,
          hasCode: hasCode,
          saving: vm.saving,
          sharing: vm.sharing,
          lastSavedPath: vm.lastSavedPath,
          onSave: () async {
            await vm.saveGeneratedCode(
              captureBytes: () => _captureCodePngBytes(vm, payload),
            );
          },
          onShare: () async {
            await vm.shareGeneratedCode(
              captureBytes: () => _captureCodePngBytes(vm, payload),
            );
          },
        ),
        const SizedBox(height: 12),
        CreatePresetSection(
          presets: vm.presets,
          onPresetNameChanged: (value) => vm.presetName = value,
          onSavePreset: vm.savePreset,
          onLoadPreset: vm.loadPreset,
          onDeletePreset: vm.deletePreset,
        ),
      ],
    );
  }

  Future<Uint8List?> _captureCodePngBytes(
    CreateProvider vm,
    String payload,
  ) async {
    try {
      final liveBytes = await vm.previewShot.capture(pixelRatio: 3);
      if (liveBytes != null) return liveBytes;
      await Future<void>.delayed(const Duration(milliseconds: 16));
      return _fallbackController.captureFromWidget(
        Material(
          color: Colors.transparent,
          child: Theme(
            data: vm.materialTheme,
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: CodeFrameWidget(
                    frameId: vm.frameId,
                    theme: vm.activeTheme,
                    header: vm.header,
                    footer: vm.footer,
                    metaLine: payload.isEmpty
                        ? ''
                        : (vm.currentValues['pn']?.toString() ??
                              vm.currentValues['name']?.toString() ??
                              vm.currentValues['url']?.toString() ??
                              vm.currentValues['value']?.toString() ??
                              ''),
                    child: Container(
                      color: vm.activeTheme.light,
                      padding: const EdgeInsets.all(14),
                      child: _buildPreviewCode(vm, payload),
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

  Widget _buildField(CreateProvider vm, FieldSpec field, dynamic value) {
    final current = value ?? field.defaultValue;
    final requiredLabel = _fieldLabel(field);
    switch (field.kind) {
      case FieldKind.select:
        return DropdownButtonFormField<String>(
          key: ValueKey<String>(
            'field-${field.name}-${current?.toString() ?? field.options.first}',
          ),
          initialValue: current?.toString().isNotEmpty == true
              ? current.toString()
              : field.options.first,
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
          onChanged: (next) => vm.setField(field.name, next ?? ''),
        );
      case FieldKind.checkbox:
        return SwitchListTile.adaptive(
          title: requiredLabel,
          subtitle: Text(field.helperText),
          value: current == true,
          onChanged: (next) => vm.setField(field.name, next),
          contentPadding: EdgeInsets.zero,
        );
      default:
        return TextFormField(
          key: ValueKey<String>(
            'field-${field.name}-${current?.toString() ?? ''}',
          ),
          focusNode: vm.focusNodeForField(field.name),
          initialValue: current?.toString() ?? '',
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
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
          onChanged: (next) => vm.setField(field.name, next),
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

  Widget _buildPreviewCode(CreateProvider vm, String payload) {
    if (vm.mode == CodeMode.qr) {
      return QrPreviewWidget(
        payload: payload,
        qrStyleId: vm.qrStyleId,
        cornerStyleId: vm.cornerStyleId,
        qrErrorLevel: vm.qrErrorLevel,
        theme: vm.activeTheme,
      );
    }

    final barcode = barcodeFactoryFor(vm.selectedUseCase.id);
    final square = isSquareBarcode(vm.selectedUseCase.id);
    return BarcodeWidget(
      barcode: barcode,
      data: payload,
      width: square ? 230 : 320,
      height: square ? 230 : 120,
      drawText: !square,
      color: vm.activeTheme.dark,
      backgroundColor: vm.activeTheme.light,
    );
  }
}
