import '../models/app_models.dart';

ScanInsight describeScan(String raw, String format) {
  final trimmed = raw.trim();
  final fields = <KeyValue>[];
  final useful = <KeyValue>[KeyValue('Format', format.replaceAll('_', ' ')), KeyValue('Characters', '${trimmed.length}'), KeyValue('Encoding', RegExp(r'^\d+$').hasMatch(trimmed) ? 'Numeric' : 'Text / Mixed')];
  String title = 'Scanned Result';
  String type = format.replaceAll('_', ' ');

  if (trimmed.startsWith('upi://pay?')) {
    final uri = Uri.parse(trimmed);
    type = 'UPI QR';
    title = 'UPI Payment';
    addField(fields, 'UPI ID', uri.queryParameters['pa']);
    addField(fields, 'Payee Name', uri.queryParameters['pn']);
    addField(fields, 'Amount', uri.queryParameters['am']);
    addField(fields, 'Currency', uri.queryParameters['cu']);
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
          addField(fields, 'SSID', value);
        case 'T':
          addField(fields, 'Security', value);
        case 'P':
          addField(fields, 'Password', value);
        case 'H':
          addField(fields, 'Hidden', value);
      }
    }
  } else if (trimmed.startsWith('BEGIN:VCARD')) {
    type = 'vCard QR';
    title = 'Contact Card';
    for (final line in trimmed.split('\n')) {
      if (!line.contains(':')) continue;
      if (line.startsWith('FN:')) addField(fields, 'Full Name', line.substring(3));
      if (line.startsWith('ORG:')) addField(fields, 'Organization', line.substring(4));
      if (line.startsWith('TEL:')) addField(fields, 'Phone', line.substring(4));
      if (line.startsWith('EMAIL:')) addField(fields, 'Email', line.substring(6));
      if (line.startsWith('URL:')) addField(fields, 'Website', line.substring(4));
    }
  } else if (trimmed.startsWith('BEGIN:VCALENDAR')) {
    type = 'Calendar QR';
    title = 'Calendar Event';
  } else if (trimmed.startsWith('mailto:')) {
    type = 'Email QR';
    title = 'Email Draft';
    final uri = Uri.parse(trimmed);
    addField(fields, 'To', uri.path);
    addField(fields, 'Subject', uri.queryParameters['subject']);
    addField(fields, 'Body', uri.queryParameters['body']);
  } else if (trimmed.startsWith('sms:')) {
    type = 'SMS QR';
    title = 'SMS Shortcut';
  } else if (trimmed.startsWith('geo:')) {
    type = 'Geo QR';
    title = 'Location';
  } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    type = 'URL QR';
    title = 'Website / Link';
    final uri = Uri.tryParse(trimmed);
    addField(fields, 'URL', trimmed);
    if (uri != null) {
      addField(fields, 'Host', uri.host);
      addField(fields, 'Path', uri.path);
    }
  }

  return ScanInsight(typeLabel: type.isEmpty ? 'Unknown' : type, title: title, payload: trimmed, fields: fields, usefulInfo: useful);
}

void addField(List<KeyValue> list, String label, String? value) {
  if (value == null || value.trim().isEmpty) return;
  list.add(KeyValue(label, value.trim()));
}
