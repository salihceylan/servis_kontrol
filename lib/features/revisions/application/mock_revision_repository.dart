import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/revisions/domain/revision_item.dart';

class MockRevisionRepository {
  const MockRevisionRepository();

  List<RevisionItem> loadFor(AppUser user) {
    final today = DateTime.now();

    DateTime atDay(int offset, {int hour = 12, int minute = 0}) {
      final base = DateTime(today.year, today.month, today.day);
      return base.add(
        Duration(days: offset, hours: hour, minutes: minute),
      );
    }

    List<RevisionHistoryEntry> history(
      List<(String, String, String, DateTime)> rows,
    ) {
      return [
        for (final row in rows)
          RevisionHistoryEntry(
            title: row.$1,
            detail: row.$2,
            actor: row.$3,
            timestamp: row.$4,
          ),
      ];
    }

    return switch (user.role) {
      UserRole.employee => [
        RevisionItem(
          id: 'emp-rev-1',
          title: 'Panel etiketi',
          project: 'Merkez Plaza',
          owner: user.firstName,
          stage: RevisionStage.inRevision,
          revisionCount: 1,
          updatedAt: atDay(0, hour: 10, minute: 15),
          category: 'Etiket',
          summary:
              'Yakın plan okunurluk düşük bulundu. Yeni fotoğraf ve kısa açıklama notu bekleniyor.',
          revisionReason:
              'Etiket seri numarası fotoğrafta net okunmuyor. Yakın plan tekrar çekilmeli.',
          histories: history([
            (
              'Revizyon istendi',
              'Etiket seri numarası net değil.',
              'Seda',
              atDay(0, hour: 10, minute: 15),
            ),
            (
              'Teslim edildi',
              'İlk yükleme lider incelemesine gönderildi.',
              user.firstName,
              atDay(-1, hour: 18, minute: 20),
            ),
          ]),
        ),
        RevisionItem(
          id: 'emp-rev-2',
          title: 'Pompa kontrol formu',
          project: 'Nova Residence',
          owner: user.firstName,
          stage: RevisionStage.pendingReview,
          revisionCount: 0,
          updatedAt: atDay(0, hour: 9, minute: 30),
          category: 'Form',
          summary:
              'Görev lider incelemesinde. Onay veya ek geri bildirim bekleniyor.',
          histories: history([
            (
              'Teslim edildi',
              'Kontrol formu incelemeye gönderildi.',
              user.firstName,
              atDay(0, hour: 9, minute: 30),
            ),
          ]),
        ),
      ],
      UserRole.teamLead => [
        RevisionItem(
          id: 'lead-rev-1',
          title: 'Asansör test formu',
          project: 'Kuzey Atölye',
          owner: 'Ece',
          stage: RevisionStage.pendingReview,
          revisionCount: 0,
          updatedAt: atDay(0, hour: 9, minute: 5),
          category: 'Form',
          summary:
              'Teslim paketi lider kararını bekliyor. Form, imza ve saha notu hazır.',
          histories: history([
            (
              'Teslim edildi',
              'Görev lider incelemesine gönderildi.',
              'Ece',
              atDay(0, hour: 9, minute: 5),
            ),
          ]),
        ),
        RevisionItem(
          id: 'lead-rev-2',
          title: 'UPS kapasite etiketi',
          project: 'Kuzey Atölye',
          owner: 'Onur',
          stage: RevisionStage.inRevision,
          revisionCount: 2,
          updatedAt: atDay(0, hour: 11, minute: 20),
          category: 'Etiket',
          summary:
              'İkinci revizyon döngüsünde. Aynı görev bir kez daha net fotoğraf bekliyor.',
          revisionReason:
              'UPS etiketinde güç değeri okunmuyor. Yeni yakın plan ve açıklama girilmeli.',
          histories: history([
            (
              'Revizyon istendi',
              'UPS etiketi okunurluğu yetersiz.',
              'Seda',
              atDay(0, hour: 11, minute: 20),
            ),
            (
              'Çalışan güncelledi',
              'İkinci fotoğraf seti eklendi.',
              'Onur',
              atDay(-1, hour: 17, minute: 35),
            ),
          ]),
        ),
        RevisionItem(
          id: 'lead-rev-3',
          title: 'Jeneratör bakım notu',
          project: 'Merkez Plaza',
          owner: 'Burak',
          stage: RevisionStage.completed,
          revisionCount: 1,
          updatedAt: atDay(-1, hour: 16, minute: 45),
          category: 'Rapor',
          summary:
              'Onay tamamlandı. Performans verisi üretildi ve rapor arşivine aktarıldı.',
          performanceReady: true,
          histories: history([
            (
              'Onaylandı',
              'Revizyon kapatıldı, performans verisi üretildi.',
              'Seda',
              atDay(-1, hour: 16, minute: 45),
            ),
          ]),
        ),
      ],
      UserRole.manager => [
        RevisionItem(
          id: 'mgr-rev-1',
          title: 'Yangın paneli raporu',
          project: 'Nova Residence',
          owner: 'Seda',
          stage: RevisionStage.pendingReview,
          revisionCount: 0,
          updatedAt: atDay(0, hour: 9, minute: 40),
          category: 'Rapor',
          summary:
              'Yönetici onayı için bekliyor. Son teslim öncesi nihai karar gerekiyor.',
          histories: history([
            (
              'Lider onayı sonrası yönetime taşındı',
              'Nihai karar için sıraya alındı.',
              'Seda',
              atDay(0, hour: 9, minute: 40),
            ),
          ]),
        ),
        RevisionItem(
          id: 'mgr-rev-2',
          title: 'Kamera altyapısı',
          project: 'Merkez Plaza',
          owner: 'Onur',
          stage: RevisionStage.inRevision,
          revisionCount: 3,
          updatedAt: atDay(0, hour: 10, minute: 25),
          category: 'Toplantı',
          summary:
              'Revizyon sayısı eşiği aştı. Erken uyarı tetiklendi ve yönetici bayrağı açıldı.',
          revisionReason:
              'Toplantı notu ile kablo rotası yeniden doğrulanmalı. Slack ve e-posta uyarısı gönderildi.',
          earlyWarning: true,
          histories: history([
            (
              'Erken uyarı tetiklendi',
              'Revizyon sayısı 3 oldu. Yönetici bayrağı açıldı.',
              'Sistem',
              atDay(0, hour: 10, minute: 25),
            ),
            (
              'Revizyon istendi',
              'Toplantı planı ve kablo rotası eksik.',
              'Merve',
              atDay(-1, hour: 15, minute: 10),
            ),
          ]),
        ),
        RevisionItem(
          id: 'mgr-rev-3',
          title: 'Asansör test formu',
          project: 'Kuzey Atölye',
          owner: 'Ece',
          stage: RevisionStage.completed,
          revisionCount: 1,
          updatedAt: atDay(-1, hour: 16, minute: 5),
          category: 'Form',
          summary:
              'Nihai onay verildi. Performans verisi ve tamamlanma kaydı üretildi.',
          performanceReady: true,
          histories: history([
            (
              'Onaylandı',
              'Form paketi tamamlandı.',
              'Merve',
              atDay(-1, hour: 16, minute: 5),
            ),
          ]),
        ),
      ],
    };
  }
}
