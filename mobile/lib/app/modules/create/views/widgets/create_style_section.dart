import 'package:flutter/material.dart';

import '../../../../../core/data/app_catalog.dart';
import '../../../../../core/models/app_models.dart';
import '../../../../views/widgets/app_widgets.dart';

class CreateStyleSection extends StatelessWidget {
  const CreateStyleSection({
    super.key,
    required this.mode,
    required this.header,
    required this.footer,
    required this.generatorThemeId,
    required this.frameId,
    required this.qrStyleId,
    required this.cornerStyleId,
    required this.qrErrorLevel,
    required this.themes,
    required this.onHeaderChanged,
    required this.onFooterChanged,
    required this.onGeneratorThemeChanged,
    required this.onFrameChanged,
    required this.onQrStyleChanged,
    required this.onCornerStyleChanged,
    required this.onErrorLevelChanged,
  });

  final CodeMode mode;
  final String header;
  final String footer;
  final String generatorThemeId;
  final String frameId;
  final String qrStyleId;
  final String cornerStyleId;
  final String qrErrorLevel;
  final List<ThemeSpec> themes;
  final ValueChanged<String> onHeaderChanged;
  final ValueChanged<String> onFooterChanged;
  final ValueChanged<String> onGeneratorThemeChanged;
  final ValueChanged<String> onFrameChanged;
  final ValueChanged<String> onQrStyleChanged;
  final ValueChanged<String> onCornerStyleChanged;
  final ValueChanged<String> onErrorLevelChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
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
              key: ValueKey(header),
              initialValue: header,
              decoration: const InputDecoration(
                labelText: 'Header',
                border: OutlineInputBorder(),
              ),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              onChanged: onHeaderChanged,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey(footer),
              initialValue: footer,
              decoration: const InputDecoration(
                labelText: 'Footer',
                border: OutlineInputBorder(),
              ),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              onChanged: onFooterChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey<String>('theme-$generatorThemeId'),
              initialValue: generatorThemeId,
              decoration: const InputDecoration(
                labelText: 'Theme',
                border: OutlineInputBorder(),
              ),
              items: themes
                  .map(
                    (theme) => DropdownMenuItem<String>(
                      value: theme.id,
                      child: Text(theme.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onGeneratorThemeChanged(value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey<String>('frame-$frameId'),
              initialValue: frameId,
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
              onChanged: (value) {
                if (value != null) onFrameChanged(value);
              },
            ),
            if (mode == CodeMode.qr) ...<Widget>[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey<String>('qrstyle-$qrStyleId'),
                initialValue: qrStyleId,
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
                onChanged: (value) {
                  if (value != null) onQrStyleChanged(value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey<String>('corner-$cornerStyleId'),
                initialValue: cornerStyleId,
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
                onChanged: (value) {
                  if (value != null) onCornerStyleChanged(value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey<String>('error-$qrErrorLevel'),
                initialValue: qrErrorLevel,
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
                onChanged: (value) {
                  if (value != null) onErrorLevelChanged(value);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
