import 'package:flutter/material.dart';

import '../../../../core/data/app_catalog.dart';
import '../../../providers/qrcodet_provider.dart';
import '../../../views/widgets/app_widgets.dart';

class SettingsTabView extends StatelessWidget {
  const SettingsTabView({super.key, required this.vm});

  final SettingsProvider vm;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: vm.smoothScroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const AppSectionTitle(kicker: 'Theme', title: 'App and generator defaults'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>('settings-app-theme-${vm.settings.appThemeId}'),
                  initialValue: vm.settings.appThemeId,
                  decoration: const InputDecoration(labelText: 'App theme', border: OutlineInputBorder()),
                  items: vm.themes.map((theme) => DropdownMenuItem<String>(value: theme.id, child: Text(theme.label))).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      vm.updateSetting(vm.settings.copyWith(appThemeId: value));
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>('settings-generator-theme-${vm.settings.generatorThemeId}'),
                  initialValue: vm.settings.generatorThemeId,
                  decoration: const InputDecoration(labelText: 'Default generator theme', border: OutlineInputBorder()),
                  items: vm.themes.map((theme) => DropdownMenuItem<String>(value: theme.id, child: Text(theme.label))).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      vm.runSetState(() => vm.generatorThemeId = value);
                      vm.updateSetting(vm.settings.copyWith(generatorThemeId: value));
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>('settings-frame-${vm.settings.defaultFrameId}'),
                  initialValue: vm.settings.defaultFrameId,
                  decoration: const InputDecoration(labelText: 'Default frame', border: OutlineInputBorder()),
                  items: frameLabels.entries
                      .map((entry) => DropdownMenuItem<String>(value: entry.key, child: Text(entry.value)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      vm.runSetState(() => vm.frameId = value);
                      vm.updateSetting(vm.settings.copyWith(defaultFrameId: value));
                    }
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
                const AppSectionTitle(kicker: 'Scanner', title: 'Camera and detection settings'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>('settings-focus-${vm.settings.focusProfile}'),
                  initialValue: vm.settings.focusProfile,
                  decoration: const InputDecoration(labelText: 'Camera focus profile', border: OutlineInputBorder()),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(value: 'balanced', child: Text('Balanced')),
                    DropdownMenuItem<String>(value: 'macro', child: Text('Close-up / Macro')),
                    DropdownMenuItem<String>(value: 'fast', child: Text('Fast motion')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      vm.updateSetting(vm.settings.copyWith(focusProfile: value));
                    }
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto zoom assist'),
                  subtitle: const Text('Help the scanner lock onto far-away codes.'),
                  value: vm.settings.autoZoom,
                  onChanged: (value) => vm.updateSetting(vm.settings.copyWith(autoZoom: value)),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Prefer front camera'),
                  subtitle: const Text('Useful for demos and mirrored scanning setups.'),
                  value: vm.settings.preferFrontCamera,
                  onChanged: (value) => vm.updateSetting(vm.settings.copyWith(preferFrontCamera: value)),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Haptic feedback on scan'),
                  subtitle: const Text('Vibrates once when a scan is detected.'),
                  value: vm.settings.hapticsEnabled,
                  onChanged: (value) => vm.updateSetting(vm.settings.copyWith(hapticsEnabled: value)),
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
                const AppSectionTitle(kicker: 'Storage', title: 'Save folder and gallery controls'),
                const SizedBox(height: 12),
                Text('Current save folder', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SelectableText(
                  vm.settings.saveDirectoryPath,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
                if (vm.lastSavedPath.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text('Last saved file', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SelectableText(
                    vm.lastSavedPath,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: vm.pickSaveDirectory,
                      icon: const Icon(Icons.drive_file_move_outline),
                      label: const Text('Change Save Folder'),
                    ),
                    OutlinedButton.icon(
                      onPressed: vm.openSaveFolderAction,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Open Save Folder'),
                    ),
                  ],
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
                const AppSectionTitle(kicker: 'History', title: 'Limit and cleanup'),
                const SizedBox(height: 8),
                Text('Stored scans: ${vm.history.length} / ${vm.settings.historyLimit}', style: Theme.of(context).textTheme.bodyMedium),
                Slider(
                  min: 10,
                  max: 1000,
                  divisions: 99,
                  value: vm.settings.historyLimit.clamp(10, 1000).toDouble(),
                  label: '${vm.settings.historyLimit.toInt()}',
                  onChanged: (value) async {
                    final nextLimit = ((value / 10).round() * 10).clamp(10, 1000);
                    await vm.updateHistoryLimit(nextLimit);
                  },
                ),
                OutlinedButton.icon(
                  onPressed: vm.clearHistory,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Clear Scan History'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
