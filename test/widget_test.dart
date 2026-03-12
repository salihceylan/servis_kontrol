import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/app.dart';

void main() {
  testWidgets('login ekranindan yonetici dashboardina gecilir', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ServisKontrolApp());
    await tester.pumpAndSettle();

    expect(find.text('Giris Yap'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'yonetici@workflow.local',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Workflow2026!',
    );
    await tester.tap(find.text('Oturum Ac'));
    await tester.pumpAndSettle();

    expect(find.text('Hos geldiniz, Merve'), findsOneWidget);
    expect(find.text('Gorev Ata'), findsOneWidget);
    expect(find.text('Workflow Is Takip Platformu'), findsOneWidget);
    expect(find.text('Bildirim Merkezi'), findsOneWidget);
  });

  testWidgets('ilk giris yapan ekip lideri onboarding gorur', (tester) async {
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
    await tester.tap(find.text('Oturum Ac'));
    await tester.pumpAndSettle();

    expect(find.text('Ilk giris kurulumu'), findsOneWidget);
    expect(find.text('Devam Et'), findsOneWidget);
  });
}
