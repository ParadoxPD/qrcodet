import 'package:barcode_widget/barcode_widget.dart' hide Barcode;
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

import '../../../../../core/logic/generator_logic.dart';
import '../../../../../core/models/app_models.dart';
import '../../../../views/widgets/app_widgets.dart';
import 'qr_preview_renderer.dart';

class CreatePreviewSection extends StatelessWidget {
  const CreatePreviewSection({
    super.key,
    required this.previewController,
    required this.mode,
    required this.barcodeUseCaseId,
    required this.frameId,
    required this.theme,
    required this.header,
    required this.footer,
    required this.metaLine,
    required this.payload,
    required this.qrStyleId,
    required this.cornerStyleId,
    required this.qrErrorLevel,
    required this.hasCode,
    required this.saving,
    required this.sharing,
    required this.lastSavedPath,
    required this.onSave,
    required this.onShare,
  });

  final ScreenshotController previewController;
  final CodeMode mode;
  final String barcodeUseCaseId;
  final String frameId;
  final ThemeSpec theme;
  final String header;
  final String footer;
  final String metaLine;
  final String payload;
  final String qrStyleId;
  final String cornerStyleId;
  final String qrErrorLevel;
  final bool hasCode;
  final bool saving;
  final bool sharing;
  final String lastSavedPath;
  final Future<void> Function() onSave;
  final Future<void> Function() onShare;

  @override
  Widget build(BuildContext context) {
    return Card(
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
              controller: previewController,
              child: CodeFrameWidget(
                frameId: frameId,
                theme: theme,
                header: header,
                footer: footer,
                metaLine: metaLine,
                child: Container(
                  color: theme.light,
                  padding: const EdgeInsets.all(14),
                  child: Center(
                    child: hasCode
                        ? (mode == CodeMode.qr
                              ? QrPreviewWidget(
                                  payload: payload,
                                  qrStyleId: qrStyleId,
                                  cornerStyleId: cornerStyleId,
                                  qrErrorLevel: qrErrorLevel,
                                  theme: theme,
                                )
                              : _buildBarcodePreview())
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
                  onPressed: (saving || sharing) ? null : onSave,
                  icon: const Icon(Icons.download_rounded),
                  label: Text(saving ? 'Saving...' : 'Save PNG'),
                ),
                OutlinedButton.icon(
                  onPressed: (saving || sharing) ? null : onShare,
                  icon: const Icon(Icons.share_rounded),
                  label: Text(sharing ? 'Sharing...' : 'Share PNG'),
                ),
              ],
            ),
            if (lastSavedPath.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                'Last save: $lastSavedPath',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Encoded payload',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SelectableText(
                payload.isEmpty ? 'Nothing encoded yet.' : payload,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodePreview() {
    final barcode = barcodeFactoryFor(barcodeUseCaseId);
    final square = isSquareBarcode(barcodeUseCaseId);
    return BarcodeWidget(
      barcode: barcode,
      data: payload,
      width: square ? 230 : 320,
      height: square ? 230 : 120,
      drawText: !square,
      color: theme.dark,
      backgroundColor: theme.light,
    );
  }
}
