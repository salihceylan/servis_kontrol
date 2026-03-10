import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/main.dart';

void main() {
  testWidgets('Servis kontrol shell renders', (tester) async {
    await tester.pumpWidget(const ServisKontrolApp());
    await tester.pumpAndSettle();

    expect(find.text('Hos geldiniz, Admin'), findsOneWidget);
    expect(find.text('Gorev Olustur'), findsOneWidget);
    expect(find.text('Performans ve Trendler'), findsOneWidget);
  });
}
