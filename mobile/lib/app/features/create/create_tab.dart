part of '../../qrcodet_app.dart';

extension _CreateTabSection on _QRCodetAppState {
  Widget _buildCreateTab() {
    final payload = _payload;
    final error = _payloadError;
    final useCases = _mode == CodeMode.qr ? _qrUseCases : _barcodeUseCases;
    final values = _currentValues;
    final hasCode = payload.isNotEmpty && error.isEmpty;

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
                const _SectionTitle(kicker: 'Mode', title: 'Choose your code type'),
                const SizedBox(height: 12),
                SegmentedButton<CodeMode>(
                  segments: const <ButtonSegment<CodeMode>>[
                    ButtonSegment<CodeMode>(value: CodeMode.qr, label: Text('QR Codes'), icon: Icon(Icons.grid_view_rounded)),
                    ButtonSegment<CodeMode>(value: CodeMode.barcode, label: Text('Barcodes'), icon: Icon(Icons.view_stream_rounded)),
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
                  decoration: const InputDecoration(labelText: 'Use case', border: OutlineInputBorder()),
                  items: useCases
                      .map((item) => DropdownMenuItem<String>(
                            value: item.id,
                            child: Tooltip(
                              message: item.description,
                              child: Text(item.label, overflow: TextOverflow.ellipsis),
                            ),
                          ))
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
                const _SectionTitle(kicker: 'Data', title: 'Fill the payload fields'),
                const SizedBox(height: 12),
                ..._selectedUseCase.fields.map((field) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildField(field, values[field.name]),
                    )),
                if (error.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(error, style: TextStyle(color: Colors.red.shade300)),
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
                const _SectionTitle(kicker: 'Style', title: 'Tune the frame and theme'),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _header,
                  decoration: const InputDecoration(labelText: 'Header', border: OutlineInputBorder()),
                  onChanged: (value) => _runSetState(() => _header = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _footer,
                  decoration: const InputDecoration(labelText: 'Footer', border: OutlineInputBorder()),
                  onChanged: (value) => _runSetState(() => _footer = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>('theme-$_generatorThemeId'),
                  initialValue: _generatorThemeId,
                  decoration: const InputDecoration(labelText: 'Theme', border: OutlineInputBorder()),
                  items: _themes.map((theme) => DropdownMenuItem<String>(value: theme.id, child: Text(theme.label))).toList(),
                  onChanged: (value) => _runSetState(() => _generatorThemeId = value ?? _generatorThemeId),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>('frame-$_frameId'),
                  initialValue: _frameId,
                  decoration: const InputDecoration(labelText: 'Frame', border: OutlineInputBorder()),
                  items: frameLabels.entries.map((entry) => DropdownMenuItem<String>(value: entry.key, child: Text(entry.value))).toList(),
                  onChanged: (value) => _runSetState(() => _frameId = value ?? _frameId),
                ),
                if (_mode == CodeMode.qr) ...<Widget>[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>('qrstyle-$_qrStyleId'),
                    initialValue: _qrStyleId,
                    decoration: const InputDecoration(labelText: 'QR dot style', border: OutlineInputBorder()),
                    items: qrStyleLabels.entries.map((entry) => DropdownMenuItem<String>(value: entry.key, child: Text(entry.value))).toList(),
                    onChanged: (value) => _runSetState(() => _qrStyleId = value ?? _qrStyleId),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>('corner-$_cornerStyleId'),
                    initialValue: _cornerStyleId,
                    decoration: const InputDecoration(labelText: 'Corner style', border: OutlineInputBorder()),
                    items: cornerStyleLabels.entries.map((entry) => DropdownMenuItem<String>(value: entry.key, child: Text(entry.value))).toList(),
                    onChanged: (value) => _runSetState(() => _cornerStyleId = value ?? _cornerStyleId),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>('error-$_qrErrorLevel'),
                    initialValue: _qrErrorLevel,
                    decoration: const InputDecoration(labelText: 'Error correction', border: OutlineInputBorder()),
                    items: const <String>['L', 'M', 'Q', 'H'].map((level) => DropdownMenuItem<String>(value: level, child: Text(level))).toList(),
                    onChanged: (value) => _runSetState(() => _qrErrorLevel = value ?? _qrErrorLevel),
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
                const _SectionTitle(kicker: 'Preview', title: 'Live preview and export'),
                const SizedBox(height: 12),
                Screenshot(
                  controller: _previewShot,
                  child: CodeFrameWidget(
                    frameId: _frameId,
                    theme: _activeTheme,
                    header: _header,
                    footer: _footer,
                    metaLine: payload.isEmpty ? '' : (_currentValues['pn']?.toString() ?? _currentValues['name']?.toString() ?? _currentValues['url']?.toString() ?? _currentValues['value']?.toString() ?? ''),
                    child: Container(
                      color: _activeTheme.light,
                      padding: const EdgeInsets.all(14),
                      child: Center(child: hasCode ? _buildPreviewCode(payload) : const Text('Fill required fields to generate')),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _saving ? null : _saveGeneratedCode,
                      icon: const Icon(Icons.download_rounded),
                      label: Text(_saving ? 'Saving...' : 'Save PNG'),
                    ),
                  ],
                ),
                if (_lastSavedPath.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text('Last save: $_lastSavedPath', style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 12),
                Text('Encoded payload', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _materialTheme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SelectableText(payload.isEmpty ? 'Nothing encoded yet.' : payload, style: const TextStyle(fontFamily: 'monospace')),
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
                const _SectionTitle(kicker: 'Presets', title: 'Reusable mobile presets'),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Preset name', border: OutlineInputBorder()),
                        onChanged: (value) => _presetName = value,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(onPressed: _savePreset, child: const Text('Save')),
                  ],
                ),
                const SizedBox(height: 12),
                if (_presets.isEmpty)
                  const Text('No presets yet.')
                else
                  ..._presets.take(8).map(
                        (preset) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(preset.name),
                          subtitle: Text('${preset.mode.toUpperCase()} / ${preset.useCaseId}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(onPressed: () => _loadPreset(preset), icon: const Icon(Icons.upload_rounded)),
                              IconButton(onPressed: () => _deletePreset(preset.id), icon: const Icon(Icons.delete_outline_rounded)),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(FieldSpec field, dynamic value) {
    final current = value ?? field.defaultValue;
    final requiredLabel = _fieldLabel(field);
    switch (field.kind) {
      case FieldKind.select:
        return DropdownButtonFormField<String>(
          key: ValueKey<String>('field-${field.name}-${current?.toString() ?? field.options.first}'),
          initialValue: (current?.toString().isNotEmpty == true ? current.toString() : field.options.first),
          decoration: InputDecoration(label: requiredLabel, border: const OutlineInputBorder(), helperText: field.helperText),
          items: field.options.map((option) => DropdownMenuItem<String>(value: option, child: Text(option))).toList(),
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
          initialValue: current?.toString() ?? '',
          keyboardType: field.kind == FieldKind.number
              ? const TextInputType.numberWithOptions(decimal: true)
              : field.kind == FieldKind.datetime
                  ? TextInputType.datetime
                  : TextInputType.text,
          maxLines: field.name == 'body' || field.name == 'text' || field.name == 'description' ? 3 : 1,
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
          const TextSpan(text: ' *', style: TextStyle(color: Colors.redAccent)),
        ],
      ),
    );
  }

  Widget _buildPreviewCode(String payload) {
    if (_mode == CodeMode.qr) {
      return QrImageView(
        data: payload,
        size: 250,
        backgroundColor: _activeTheme.light,
        errorCorrectionLevel: toQrErrorLevel(_qrErrorLevel),
        eyeStyle: QrEyeStyle(eyeShape: _cornerStyleId == 'dot' ? QrEyeShape.circle : QrEyeShape.square, color: _activeTheme.dark),
        dataModuleStyle: QrDataModuleStyle(dataModuleShape: _qrStyleId == 'dot' ? QrDataModuleShape.circle : QrDataModuleShape.square, color: _activeTheme.dark),
        embeddedImage: _logoBytes == null ? null : MemoryImage(_logoBytes!),
        embeddedImageStyle: const QrEmbeddedImageStyle(size: Size.square(40)),
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
}
