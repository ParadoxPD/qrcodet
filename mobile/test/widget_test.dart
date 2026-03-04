import 'package:flutter_test/flutter_test.dart';
import 'package:qrcodet_mobile/app/qrcodet_app.dart';

void main() {
  testWidgets('app loads primary navigation labels', (tester) async {
    await tester.pumpWidget(const QRCodetApp());
    await tester.pumpAndSettle();

    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
