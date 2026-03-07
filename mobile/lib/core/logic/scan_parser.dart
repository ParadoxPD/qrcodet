import '../models/app_models.dart';

final RegExp _numericPattern = RegExp(r'^\d+$');

ScanInsight describeScan(String raw, String format) {
  final trimmed = raw.trim();
  final fields = <KeyValue>[];
  final useful = <KeyValue>[
    KeyValue('Format', format.replaceAll('_', ' ')),
    KeyValue('Characters', '${trimmed.length}'),
    KeyValue(
      'Encoding',
      _numericPattern.hasMatch(trimmed) ? 'Numeric' : 'Text / Mixed',
    ),
  ];
  String title = 'Scanned Result';
  String type = format.replaceAll('_', ' ');

  if (trimmed.startsWith('upi://pay?')) {
    final uri = Uri.parse(trimmed);
    type = 'UPI QR';
    title = 'UPI Payment';
    _addField(fields, 'UPI ID', uri.queryParameters['pa']);
    _addField(fields, 'Payee Name', uri.queryParameters['pn']);
    _addField(fields, 'Amount', uri.queryParameters['am']);
    _addField(fields, 'Currency', uri.queryParameters['cu']);
  } else if (trimmed.startsWith('WIFI:')) {
    type = 'WiFi QR';
    title = 'WiFi Access';
    final body = trimmed.replaceFirst('WIFI:', '').replaceAll(';;', '');
    final parts = body.split(';');
    for (final part in parts) {
      if (!part.contains(':')) continue;
      final split = part.split(':');
      final key = split.first;
      final value = split.sublist(1).join(':');
      switch (key) {
        case 'S':
          _addField(fields, 'SSID', value);
        case 'T':
          _addField(fields, 'Security', value);
        case 'P':
          _addField(fields, 'Password', value);
        case 'H':
          _addField(fields, 'Hidden', value);
      }
    }
  } else if (trimmed.startsWith('BEGIN:VCARD')) {
    type = 'vCard QR';
    title = 'Contact Card';
    for (final line in trimmed.split('\n')) {
      if (!line.contains(':')) continue;
      if (line.startsWith('FN:')) {
        _addField(fields, 'Full Name', line.substring(3));
      }
      if (line.startsWith('ORG:')) {
        _addField(fields, 'Organization', line.substring(4));
      }
      if (line.startsWith('TEL:')) {
        _addField(fields, 'Phone', line.substring(4));
      }
      if (line.startsWith('EMAIL:')) {
        _addField(fields, 'Email', line.substring(6));
      }
      if (line.startsWith('URL:')) {
        _addField(fields, 'Website', line.substring(4));
      }
    }
  } else if (trimmed.startsWith('BEGIN:VCALENDAR')) {
    type = 'Calendar QR';
    title = 'Calendar Event';
  } else if (trimmed.startsWith('mailto:')) {
    type = 'Email QR';
    title = 'Email Draft';
    final uri = Uri.parse(trimmed);
    _addField(fields, 'To', uri.path);
    _addField(fields, 'Subject', uri.queryParameters['subject']);
    _addField(fields, 'Body', uri.queryParameters['body']);
  } else if (trimmed.startsWith('sms:')) {
    type = 'SMS QR';
    title = 'SMS Shortcut';
    // sms:<phone>?body=<message>  or  sms:<phone>
    final withoutScheme = trimmed.substring(4); // strip 'sms:'
    final qIndex = withoutScheme.indexOf('?');
    if (qIndex == -1) {
      _addField(fields, 'Phone', withoutScheme);
    } else {
      _addField(fields, 'Phone', withoutScheme.substring(0, qIndex));
      final query = Uri.splitQueryString(withoutScheme.substring(qIndex + 1));
      _addField(fields, 'Message', query['body']);
    }
  } else if (trimmed.startsWith('geo:')) {
    type = 'Geo QR';
    title = 'Location';
    // geo:<lat>,<lng>  or  geo:<lat>,<lng>?q=<label>
    final withoutScheme = trimmed.substring(4); // strip 'geo:'
    final qIndex = withoutScheme.indexOf('?');
    final coords = qIndex == -1
        ? withoutScheme
        : withoutScheme.substring(0, qIndex);
    final parts = coords.split(',');
    if (parts.length >= 2) {
      _addField(fields, 'Latitude', parts[0].trim());
      _addField(fields, 'Longitude', parts[1].trim());
    }
    if (qIndex != -1) {
      final query = Uri.splitQueryString(withoutScheme.substring(qIndex + 1));
      _addField(fields, 'Label', query['q']);
    }
  } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    type = 'URL QR';
    title = 'Website / Link';
    final uri = Uri.tryParse(trimmed);
    _addField(fields, 'URL', trimmed);
    if (uri != null) {
      _addField(fields, 'Host', uri.host);
      _addField(fields, 'Path', uri.path);
    }
  }

  return ScanInsight(
    typeLabel: type.isEmpty ? 'Unknown' : type,
    title: title,
    payload: trimmed,
    fields: fields,
    usefulInfo: useful,
  );
}

void _addField(List<KeyValue> list, String label, String? value) {
  if (value == null || value.trim().isEmpty) return;
  list.add(KeyValue(label, value.trim()));
}
