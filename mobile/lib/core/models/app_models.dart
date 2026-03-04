import 'package:flutter/material.dart';

class PayloadResult {
  PayloadResult(this.payload, this.error);

  final String payload;
  final String error;
}

class ScanInsight {
  ScanInsight({required this.typeLabel, required this.title, required this.payload, required this.fields, required this.usefulInfo});

  final String typeLabel;
  final String title;
  final String payload;
  final List<KeyValue> fields;
  final List<KeyValue> usefulInfo;
}

class KeyValue {
  KeyValue(this.label, this.value);

  final String label;
  final String value;
}

class ThemeSpec {
  ThemeSpec({required this.id, required this.label, required this.dark, required this.light, required this.accent, required this.mood});

  final String id;
  final String label;
  final Color dark;
  final Color light;
  final Color accent;
  final ThemeMood mood;
}

enum ThemeMood { light, dark }

enum CodeMode { qr, barcode }

enum FieldKind { text, number, select, checkbox, datetime }

class FieldSpec {
  const FieldSpec({required this.name, required this.label, required this.helperText, this.placeholder = '', this.required = false, this.kind = FieldKind.text, this.options = const <String>[], this.defaultValue = ''});

  final String name;
  final String label;
  final String helperText;
  final String placeholder;
  final bool required;
  final FieldKind kind;
  final List<String> options;
  final dynamic defaultValue;
}

class UseCaseSpec {
  const UseCaseSpec({required this.id, required this.label, required this.description, required this.filenamePrefix, required this.builderId, required this.category, this.defaults = const <String, dynamic>{}, this.fields = const <FieldSpec>[]});

  final String id;
  final String label;
  final String description;
  final String filenamePrefix;
  final String builderId;
  final String category;
  final Map<String, dynamic> defaults;
  final List<FieldSpec> fields;
}

class AppSettings {
  AppSettings({required this.appThemeId, required this.generatorThemeId, required this.focusProfile, required this.autoZoom, required this.preferFrontCamera, required this.hapticsEnabled, required this.historyLimit, required this.saveRootPath, required this.saveDirectoryPath, required this.defaultFrameId, required this.defaultHeader, required this.defaultFooter});

  factory AppSettings.defaults() => AppSettings(appThemeId: 'noir', generatorThemeId: 'noir', focusProfile: 'balanced', autoZoom: true, preferFrontCamera: false, hapticsEnabled: true, historyLimit: 100, saveRootPath: '', saveDirectoryPath: '', defaultFrameId: 'scan', defaultHeader: 'Scan & Pay', defaultFooter: 'Powered by QRCodet');

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        appThemeId: json['appThemeId']?.toString() ?? 'noir',
        generatorThemeId: json['generatorThemeId']?.toString() ?? 'noir',
        focusProfile: json['focusProfile']?.toString() ?? 'balanced',
        autoZoom: json['autoZoom'] == true,
        preferFrontCamera: json['preferFrontCamera'] == true,
        hapticsEnabled: json['hapticsEnabled'] != false,
        historyLimit: (json['historyLimit'] as num?)?.toInt() ?? 100,
        saveRootPath: json['saveRootPath']?.toString() ?? '',
        saveDirectoryPath: json['saveDirectoryPath']?.toString() ?? '',
        defaultFrameId: json['defaultFrameId']?.toString() ?? 'scan',
        defaultHeader: json['defaultHeader']?.toString() ?? 'Scan & Pay',
        defaultFooter: json['defaultFooter']?.toString() ?? 'Powered by QRCodet',
      );

  final String appThemeId;
  final String generatorThemeId;
  final String focusProfile;
  final bool autoZoom;
  final bool preferFrontCamera;
  final bool hapticsEnabled;
  final int historyLimit;
  final String saveRootPath;
  final String saveDirectoryPath;
  final String defaultFrameId;
  final String defaultHeader;
  final String defaultFooter;

  AppSettings copyWith({String? appThemeId, String? generatorThemeId, String? focusProfile, bool? autoZoom, bool? preferFrontCamera, bool? hapticsEnabled, int? historyLimit, String? saveRootPath, String? saveDirectoryPath, String? defaultFrameId, String? defaultHeader, String? defaultFooter}) {
    return AppSettings(
      appThemeId: appThemeId ?? this.appThemeId,
      generatorThemeId: generatorThemeId ?? this.generatorThemeId,
      focusProfile: focusProfile ?? this.focusProfile,
      autoZoom: autoZoom ?? this.autoZoom,
      preferFrontCamera: preferFrontCamera ?? this.preferFrontCamera,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      historyLimit: historyLimit ?? this.historyLimit,
      saveRootPath: saveRootPath ?? this.saveRootPath,
      saveDirectoryPath: saveDirectoryPath ?? this.saveDirectoryPath,
      defaultFrameId: defaultFrameId ?? this.defaultFrameId,
      defaultHeader: defaultHeader ?? this.defaultHeader,
      defaultFooter: defaultFooter ?? this.defaultFooter,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'appThemeId': appThemeId,
        'generatorThemeId': generatorThemeId,
        'focusProfile': focusProfile,
        'autoZoom': autoZoom,
        'preferFrontCamera': preferFrontCamera,
        'hapticsEnabled': hapticsEnabled,
        'historyLimit': historyLimit,
        'saveRootPath': saveRootPath,
        'saveDirectoryPath': saveDirectoryPath,
        'defaultFrameId': defaultFrameId,
        'defaultHeader': defaultHeader,
        'defaultFooter': defaultFooter,
      };
}

class ScanRecord {
  ScanRecord({required this.id, required this.rawValue, required this.codeType, required this.title, required this.scannedAt});

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
        id: json['id'].toString(),
        rawValue: json['rawValue'].toString(),
        codeType: json['codeType'].toString(),
        title: json['title'].toString(),
        scannedAt: (json['scannedAt'] as num).toInt(),
      );

  final String id;
  final String rawValue;
  final String codeType;
  final String title;
  final int scannedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'rawValue': rawValue, 'codeType': codeType, 'title': title, 'scannedAt': scannedAt};
}

class GeneratorPreset {
  GeneratorPreset({required this.id, required this.name, required this.mode, required this.useCaseId, required this.values, required this.header, required this.footer, required this.themeId, required this.frameId, required this.qrStyleId, required this.cornerStyleId, required this.errorLevel, required this.createdAt});

  factory GeneratorPreset.fromJson(Map<String, dynamic> json) => GeneratorPreset(
        id: json['id'].toString(),
        name: json['name'].toString(),
        mode: json['mode'].toString(),
        useCaseId: json['useCaseId'].toString(),
        values: Map<String, dynamic>.from(json['values'] as Map<String, dynamic>),
        header: json['header'].toString(),
        footer: json['footer'].toString(),
        themeId: json['themeId'].toString(),
        frameId: json['frameId'].toString(),
        qrStyleId: json['qrStyleId'].toString(),
        cornerStyleId: json['cornerStyleId'].toString(),
        errorLevel: json['errorLevel'].toString(),
        createdAt: (json['createdAt'] as num).toInt(),
      );

  final String id;
  final String name;
  final String mode;
  final String useCaseId;
  final Map<String, dynamic> values;
  final String header;
  final String footer;
  final String themeId;
  final String frameId;
  final String qrStyleId;
  final String cornerStyleId;
  final String errorLevel;
  final int createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'mode': mode,
        'useCaseId': useCaseId,
        'values': values,
        'header': header,
        'footer': footer,
        'themeId': themeId,
        'frameId': frameId,
        'qrStyleId': qrStyleId,
        'cornerStyleId': cornerStyleId,
        'errorLevel': errorLevel,
        'createdAt': createdAt,
      };
}
