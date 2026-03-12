import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/app.dart';

void main() {
  testWidgets('login ekranından yönetici dashboardına geçilir', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ServisKontrolApp());
    await tester.pumpAndSettle();

    expect(find.text('Workflow Giriş'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'yonetici@workflow.local',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Workflow2026!',
    );
    await tester.tap(find.text('Oturum Aç'));
    await tester.pumpAndSettle();

    expect(find.text('Hoş geldiniz, Merve'), findsOneWidget);
    expect(find.text('Görev Ata'), findsOneWidget);
    expect(find.text('Workflow İş Takip Platformu'), findsOneWidget);
    expect(find.text('Bildirim Merkezi'), findsOneWidget);
  });

  testWidgets('ilk giriş yapan ekip lideri onboarding görür', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ServisKontrolApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'lider@workflow.local',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Workflow2026!',
    );
    await tester.tap(find.text('Oturum Aç'));
    await tester.pumpAndSettle();

    expect(find.text('İlk giriş kurulumu'), findsOneWidget);
    expect(find.text('Devam Et'), findsOneWidget);
  });
}
