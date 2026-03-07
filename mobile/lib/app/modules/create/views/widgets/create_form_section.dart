import 'package:flutter/material.dart';

import '../../../../../core/models/app_models.dart';
import '../../../../views/widgets/app_widgets.dart';

typedef BuildFieldWidget = Widget Function(FieldSpec field, dynamic value);

class CreateFormSection extends StatelessWidget {
  const CreateFormSection({
    super.key,
    required this.mode,
    required this.useCases,
    required this.selectedUseCase,
    required this.values,
    required this.onModeChanged,
    required this.onUseCaseChanged,
    required this.buildField,
    required this.error,
  });

  final CodeMode mode;
  final List<UseCaseSpec> useCases;
  final UseCaseSpec selectedUseCase;
  final Map<String, dynamic> values;
  final ValueChanged<CodeMode> onModeChanged;
  final ValueChanged<String> onUseCaseChanged;
  final BuildFieldWidget buildField;
  final String error;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  selected: <CodeMode>{mode},
                  onSelectionChanged: (selection) =>
                      onModeChanged(selection.first),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>('usecase-${selectedUseCase.id}'),
                  initialValue: selectedUseCase.id,
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
                    if (value != null) onUseCaseChanged(value);
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
                ...selectedUseCase.fields.map(
                  (field) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: buildField(field, values[field.name]),
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
      ],
    );
  }
}
