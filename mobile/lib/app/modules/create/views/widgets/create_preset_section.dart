import 'package:flutter/material.dart';

import '../../../../../core/models/app_models.dart';
import '../../../../views/widgets/app_widgets.dart';

class CreatePresetSection extends StatefulWidget {
  const CreatePresetSection({
    super.key,
    required this.presets,
    required this.onPresetNameChanged,
    required this.onSavePreset,
    required this.onLoadPreset,
    required this.onDeletePreset,
  });

  final List<GeneratorPreset> presets;
  final ValueChanged<String> onPresetNameChanged;
  final Future<void> Function() onSavePreset;
  final Future<void> Function(GeneratorPreset preset) onLoadPreset;
  final Future<void> Function(String id) onDeletePreset;

  @override
  State<CreatePresetSection> createState() => _CreatePresetSectionState();
}

class _CreatePresetSectionState extends State<CreatePresetSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final displayedPresets = _showAll
        ? widget.presets
        : widget.presets.take(8).toList();

    return Card(
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
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    onChanged: widget.onPresetNameChanged,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: widget.onSavePreset,
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.presets.isEmpty)
              const Text('No presets yet.')
            else
              ...displayedPresets.map(
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
                        onPressed: () => widget.onLoadPreset(preset),
                        icon: const Icon(Icons.upload_rounded),
                      ),
                      IconButton(
                        onPressed: () => widget.onDeletePreset(preset.id),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.presets.length > 8) ...<Widget>[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _showAll = !_showAll),
                child: Text(
                  _showAll
                      ? 'Show less'
                      : 'Show all ${widget.presets.length} presets',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
