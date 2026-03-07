import 'package:barcode/barcode.dart' as bc;
import 'package:zxing_lib/qrcode.dart';

import '../models/app_models.dart';

ErrorCorrectionLevel toQrErrorLevel(String level) {
  return switch (level) {
    'L' => ErrorCorrectionLevel.L,
    'M' => ErrorCorrectionLevel.M,
    'Q' => ErrorCorrectionLevel.Q,
    'H' => ErrorCorrectionLevel.H,
    _ => ErrorCorrectionLevel.M,
  };
}

bc.Barcode barcodeFactoryFor(String id) {
  return switch (id) {
    'code39' => bc.Barcode.code39(),
    'code93' => bc.Barcode.code93(),
    'codabar' => bc.Barcode.codabar(),
    'ean13' => bc.Barcode.ean13(),
    'upca' => bc.Barcode.upcA(),
    'upce' => bc.Barcode.upcE(),
    'ean8' => bc.Barcode.ean8(),
    'itf14' => bc.Barcode.itf14(),
    'pdf417' => bc.Barcode.pdf417(),
    'datamatrix' => bc.Barcode.dataMatrix(),
    'aztec' => bc.Barcode.aztec(),
    _ => bc.Barcode.code128(),
  };
}

bool isSquareBarcode(String id) => id == 'datamatrix' || id == 'aztec';

PayloadResult buildPayload(
  CodeMode mode,
  UseCaseSpec spec,
  Map<String, dynamic> values,
) {
  for (final field in spec.fields) {
    final value = values[field.name];
    if (field.required && (value == null || value.toString().trim().isEmpty)) {
      return PayloadResult('', '${field.label} is required.');
    }
  }
  if (mode == CodeMode.barcode) {
    final value = values['value']?.toString().trim() ?? '';
    return PayloadResult(
      value,
      value.isEmpty ? 'Barcode value is required.' : '',
    );
  }

  String getValue(String key) => values[key]?.toString().trim() ?? '';
  return switch (spec.builderId) {
    'upi' => () {
      final params = <String, String>{
        'pa': getValue('pa'),
        'pn': getValue('pn'),
        'cu': getValue('cu').isEmpty ? 'INR' : getValue('cu'),
      };
      if (getValue('am').isNotEmpty) params['am'] = getValue('am');
      if (getValue('tn').isNotEmpty) params['tn'] = getValue('tn');
      if (getValue('mc').isNotEmpty) params['mc'] = getValue('mc');
      return PayloadResult(
        'upi://pay?${Uri(queryParameters: params).query}',
        '',
      );
    }(),
    'url' || 'youtube' || 'x' => () {
      final url = getValue('url');
      return PayloadResult(
        url.startsWith('http') ? url : 'https://$url',
        url.isEmpty ? 'URL is required.' : '',
      );
    }(),
    'wifi' => () {
      final hidden = values['hidden'] == true ? 'true' : 'false';
      return PayloadResult(
        'WIFI:T:${getValue('security')};S:${getValue('ssid')};P:${getValue('password')};H:$hidden;;',
        '',
      );
    }(),
    'vcard' => PayloadResult(
      [
        'BEGIN:VCARD',
        'VERSION:3.0',
        'FN:${getValue('name')}',
        if (getValue('org').isNotEmpty) 'ORG:${getValue('org')}',
        if (getValue('phone').isNotEmpty) 'TEL:${getValue('phone')}',
        if (getValue('email').isNotEmpty) 'EMAIL:${getValue('email')}',
        if (getValue('website').isNotEmpty) 'URL:${getValue('website')}',
        'END:VCARD',
      ].join('\n'),
      '',
    ),
    'geo' => () {
      final label = getValue('label').isNotEmpty
          ? '?q=${Uri.encodeComponent(getValue('label'))}'
          : '';
      return PayloadResult(
        'geo:${getValue('lat')},${getValue('lng')}$label',
        '',
      );
    }(),
    'calendar' => PayloadResult(
      [
        'BEGIN:VCALENDAR',
        'VERSION:2.0',
        'BEGIN:VEVENT',
        'SUMMARY:${getValue('title')}',
        'DTSTART:${icsTime(getValue('start'))}',
        'DTEND:${icsTime(getValue('end'))}',
        if (getValue('location').isNotEmpty) 'LOCATION:${getValue('location')}',
        if (getValue('description').isNotEmpty)
          'DESCRIPTION:${getValue('description')}',
        'END:VEVENT',
        'END:VCALENDAR',
      ].join('\n'),
      '',
    ),
    'event' => PayloadResult(
      [
        'EVENT:${getValue('title')}',
        'START:${getValue('start')}',
        'END:${getValue('end')}',
        if (getValue('location').isNotEmpty) 'LOCATION:${getValue('location')}',
        if (getValue('host').isNotEmpty) 'HOST:${getValue('host')}',
        if (getValue('url').isNotEmpty) 'URL:${getValue('url')}',
      ].join('\n'),
      '',
    ),
    'sms' => () {
      final body = getValue('message');
      return PayloadResult(
        body.isEmpty
            ? 'sms:${getValue('phone')}'
            : 'sms:${getValue('phone')}?body=${Uri.encodeComponent(body)}',
        '',
      );
    }(),
    'email' => () {
      final query = <String, String>{};
      if (getValue('subject').isNotEmpty) {
        query['subject'] = getValue('subject');
      }
      if (getValue('body').isNotEmpty) query['body'] = getValue('body');
      return PayloadResult(
        'mailto:${getValue('to')}${query.isEmpty ? '' : '?${Uri(queryParameters: query).query}'}',
        '',
      );
    }(),
    'text' => PayloadResult(
      getValue('text'),
      getValue('text').isEmpty ? 'Text is required.' : '',
    ),
    _ => () {
      assert(
        false,
        'Unhandled builderId: ${spec.builderId}. Add a case for it in buildPayload().',
      );
      return PayloadResult('', 'Unknown builder: ${spec.builderId}');
    }(),
  };
}

String icsTime(String input) {
  final date = DateTime.tryParse(input)?.toUtc();
  if (date == null) return input;
  String pad(int value) => value.toString().padLeft(2, '0');
  return '${date.year}${pad(date.month)}${pad(date.day)}T${pad(date.hour)}${pad(date.minute)}${pad(date.second)}Z';
}

Map<String, Map<String, dynamic>> createInitialValues(
  List<UseCaseSpec> qrUseCases,
  List<UseCaseSpec> barcodeUseCases,
) {
  final map = <String, Map<String, dynamic>>{};
  for (final spec in <UseCaseSpec>[...qrUseCases, ...barcodeUseCases]) {
    final values = <String, dynamic>{};
    for (final field in spec.fields) {
      final defaultValue = field.defaultValue;
      values[field.name] = switch (field.kind) {
        FieldKind.checkbox => defaultValue is bool ? defaultValue : false,
        FieldKind.select =>
          defaultValue is String && defaultValue.isNotEmpty
              ? defaultValue
              : (field.options.isNotEmpty ? field.options.first : ''),
        _ => defaultValue?.toString() ?? '',
      };
    }
    values.addAll(spec.defaults);
    final prefix = spec.category == 'barcode' ? 'barcode' : 'qr';
    map['$prefix:${spec.id}'] = values;
  }
  return map;
}
