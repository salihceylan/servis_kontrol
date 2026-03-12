import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/app.dart';
import 'package:servis_kontrol/features/auth/presentation/login_page.dart';

void main() {
  testWidgets('uygulama varsayilan olarak login ekranini acar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ServisKontrolApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
