import 'package:barcode/barcode.dart' as bc;
import 'package:zxing_lib/qrcode.dart';

import '../models/app_models.dart';

ErrorCorrectionLevel toQrErrorLevel(String level) {
  switch (level) {
    case 'L':
      return ErrorCorrectionLevel.L;
    case 'M':
      return ErrorCorrectionLevel.M;
    case 'Q':
      return ErrorCorrectionLevel.Q;
    case 'H':
      return ErrorCorrectionLevel.H;
    default:
      return ErrorCorrectionLevel.M;
  }
}

bc.Barcode barcodeFactoryFor(String id) {
  switch (id) {
    case 'code39':
      return bc.Barcode.code39();
    case 'code93':
      return bc.Barcode.code93();
    case 'codabar':
      return bc.Barcode.codabar();
    case 'ean13':
      return bc.Barcode.ean13();
    case 'upca':
      return bc.Barcode.upcA();
    case 'upce':
      return bc.Barcode.upcE();
    case 'ean8':
      return bc.Barcode.ean8();
    case 'itf14':
      return bc.Barcode.itf14();
    case 'pdf417':
      return bc.Barcode.pdf417();
    case 'datamatrix':
      return bc.Barcode.dataMatrix();
    case 'aztec':
      return bc.Barcode.aztec();
    default:
      return bc.Barcode.code128();
  }
}

bool isSquareBarcode(String id) => id == 'datamatrix' || id == 'aztec';

PayloadResult buildPayload(CodeMode mode, UseCaseSpec spec, Map<String, dynamic> values) {
  for (final field in spec.fields) {
    final value = values[field.name];
    if (field.required && (value == null || value.toString().trim().isEmpty)) {
      return PayloadResult('', '${field.label} is required.');
    }
  }
  if (mode == CodeMode.barcode) {
    final value = values['value']?.toString().trim() ?? '';
    return PayloadResult(value, value.isEmpty ? 'Barcode value is required.' : '');
  }

  String getValue(String key) => values[key]?.toString().trim() ?? '';
  switch (spec.builderId) {
    case 'upi':
      final params = <String, String>{'pa': getValue('pa'), 'pn': getValue('pn'), 'cu': getValue('cu').isEmpty ? 'INR' : getValue('cu')};
      if (getValue('am').isNotEmpty) params['am'] = getValue('am');
      if (getValue('tn').isNotEmpty) params['tn'] = getValue('tn');
      if (getValue('mc').isNotEmpty) params['mc'] = getValue('mc');
      return PayloadResult('upi://pay?${Uri(queryParameters: params).query}', '');
    case 'url':
    case 'youtube':
    case 'x':
      final url = getValue('url');
      return PayloadResult(url.startsWith('http') ? url : 'https://$url', url.isEmpty ? 'URL is required.' : '');
    case 'wifi':
      final hidden = values['hidden'] == true ? 'true' : 'false';
      return PayloadResult('WIFI:T:${getValue('security')};S:${getValue('ssid')};P:${getValue('password')};H:$hidden;;', '');
    case 'vcard':
      return PayloadResult([
        'BEGIN:VCARD',
        'VERSION:3.0',
        'FN:${getValue('name')}',
        if (getValue('org').isNotEmpty) 'ORG:${getValue('org')}',
        if (getValue('phone').isNotEmpty) 'TEL:${getValue('phone')}',
        if (getValue('email').isNotEmpty) 'EMAIL:${getValue('email')}',
        if (getValue('website').isNotEmpty) 'URL:${getValue('website')}',
        'END:VCARD',
      ].join('\n'), '');
    case 'geo':
      final label = getValue('label').isNotEmpty ? '?q=${Uri.encodeComponent(getValue('label'))}' : '';
      return PayloadResult('geo:${getValue('lat')},${getValue('lng')}$label', '');
    case 'calendar':
      return PayloadResult([
        'BEGIN:VCALENDAR',
        'VERSION:2.0',
        'BEGIN:VEVENT',
        'SUMMARY:${getValue('title')}',
        'DTSTART:${icsTime(getValue('start'))}',
        'DTEND:${icsTime(getValue('end'))}',
        if (getValue('location').isNotEmpty) 'LOCATION:${getValue('location')}',
        if (getValue('description').isNotEmpty) 'DESCRIPTION:${getValue('description')}',
        'END:VEVENT',
        'END:VCALENDAR',
      ].join('\n'), '');
    case 'event':
      return PayloadResult([
        'EVENT:${getValue('title')}',
        'START:${getValue('start')}',
        'END:${getValue('end')}',
        if (getValue('location').isNotEmpty) 'LOCATION:${getValue('location')}',
        if (getValue('host').isNotEmpty) 'HOST:${getValue('host')}',
        if (getValue('url').isNotEmpty) 'URL:${getValue('url')}',
      ].join('\n'), '');
    case 'sms':
      final body = getValue('message');
      return PayloadResult(body.isEmpty ? 'sms:${getValue('phone')}' : 'sms:${getValue('phone')}?body=${Uri.encodeComponent(body)}', '');
    case 'email':
      final query = <String, String>{};
      if (getValue('subject').isNotEmpty) query['subject'] = getValue('subject');
      if (getValue('body').isNotEmpty) query['body'] = getValue('body');
      return PayloadResult('mailto:${getValue('to')}${query.isEmpty ? '' : '?${Uri(queryParameters: query).query}'}', '');
    default:
      return PayloadResult(getValue('text'), getValue('text').isEmpty ? 'Text is required.' : '');
  }
}

String icsTime(String input) {
  final date = DateTime.tryParse(input)?.toUtc();
  if (date == null) return input;
  String pad(int value) => value.toString().padLeft(2, '0');
  return '${date.year}${pad(date.month)}${pad(date.day)}T${pad(date.hour)}${pad(date.minute)}${pad(date.second)}Z';
}

Map<String, Map<String, dynamic>> createInitialValues(List<UseCaseSpec> qrUseCases, List<UseCaseSpec> barcodeUseCases) {
  final map = <String, Map<String, dynamic>>{};
  for (final spec in <UseCaseSpec>[...qrUseCases, ...barcodeUseCases]) {
    final values = <String, dynamic>{};
    for (final field in spec.fields) {
      values[field.name] = field.defaultValue;
    }
    values.addAll(spec.defaults);
    final prefix = spec.category == 'barcode' ? 'barcode' : 'qr';
    map['$prefix:${spec.id}'] = values;
  }
  return map;
}
