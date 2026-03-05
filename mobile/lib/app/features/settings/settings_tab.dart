part of '../../qrcodet_app.dart';

extension _SettingsTabSection on _QRCodetAppState {
  Widget _buildSettingsTab() {
    return ListView(
      physics: _smoothScroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _SectionTitle(
                  kicker: 'Theme',
                  title: 'App and generator defaults',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>(
                    'settings-app-theme-${_settings.appThemeId}',
                  ),
                  initialValue: _settings.appThemeId,
                  decoration: const InputDecoration(
                    labelText: 'App theme',
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
                  onChanged: (value) {
                    if (value != null) {
                      _updateSetting(_settings.copyWith(appThemeId: value));
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>(
                    'settings-generator-theme-${_settings.generatorThemeId}',
                  ),
                  initialValue: _settings.generatorThemeId,
                  decoration: const InputDecoration(
                    labelText: 'Default generator theme',
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
                  onChanged: (value) {
                    if (value != null) {
                      _runSetState(() => _generatorThemeId = value);
                      _updateSetting(
                        _settings.copyWith(generatorThemeId: value),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>(
                    'settings-frame-${_settings.defaultFrameId}',
                  ),
                  initialValue: _settings.defaultFrameId,
                  decoration: const InputDecoration(
                    labelText: 'Default frame',
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
                    if (value != null) {
                      _runSetState(() => _frameId = value);
                      _updateSetting(_settings.copyWith(defaultFrameId: value));
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
                const _SectionTitle(
                  kicker: 'Scanner',
                  title: 'Camera and detection settings',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>(
                    'settings-focus-${_settings.focusProfile}',
                  ),
                  initialValue: _settings.focusProfile,
                  decoration: const InputDecoration(
                    labelText: 'Camera focus profile',
                    border: OutlineInputBorder(),
                  ),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: 'balanced',
                      child: Text('Balanced'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'macro',
                      child: Text('Close-up / Macro'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'fast',
                      child: Text('Fast motion'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _updateSetting(_settings.copyWith(focusProfile: value));
                    }
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto zoom assist'),
                  subtitle: const Text(
                    'Help the scanner lock onto far-away codes.',
                  ),
                  value: _settings.autoZoom,
                  onChanged: (value) =>
                      _updateSetting(_settings.copyWith(autoZoom: value)),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Prefer front camera'),
                  subtitle: const Text(
                    'Useful for demos and mirrored scanning setups.',
                  ),
                  value: _settings.preferFrontCamera,
                  onChanged: (value) => _updateSetting(
                    _settings.copyWith(preferFrontCamera: value),
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Haptic feedback on scan'),
                  subtitle: const Text(
                    'Vibrates once when a scan is detected.',
                  ),
                  value: _settings.hapticsEnabled,
                  onChanged: (value) =>
                      _updateSetting(_settings.copyWith(hapticsEnabled: value)),
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
                const _SectionTitle(
                  kicker: 'Storage',
                  title: 'Save folder and gallery controls',
                ),
                const SizedBox(height: 12),
                Text(
                  'Current save folder',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _settings.saveDirectoryPath,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
                if (_lastSavedPath.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    'Last saved file',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _lastSavedPath,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _pickSaveDirectory,
                      icon: const Icon(Icons.drive_file_move_outline),
                      label: const Text('Change Save Folder'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _openSaveFolderAction,
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
                const _SectionTitle(
                  kicker: 'History',
                  title: 'Limit and cleanup',
                ),
                const SizedBox(height: 8),
                Text(
                  'Stored scans: ${_history.length} / ${_settings.historyLimit}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                Slider(
                  min: 10,
                  max: 1000,
                  divisions: 99,
                  value: _settings.historyLimit.clamp(10, 1000).toDouble(),
                  label: '${_settings.historyLimit.toInt()}',
                  onChanged: (value) async {
                    final nextLimit = ((value / 10).round() * 10).clamp(
                      10,
                      1000,
                    );
                    final nextHistory = _history.take(nextLimit).toList();
                    _runSetState(() => _history = nextHistory);
                    await _updateSetting(
                      _settings.copyWith(historyLimit: nextLimit),
                    );
                    await _persistHistory();
                  },
                ),
                OutlinedButton.icon(
                  onPressed: _clearHistory,
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
