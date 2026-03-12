import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/tasks/domain/task_item.dart';

class MockTaskRepository {
  const MockTaskRepository();

  List<TaskItem> loadFor(AppUser user) {
    final today = DateTime.now();

    DateTime atDay(int offset, {int hour = 17, int minute = 30}) {
      final base = DateTime(today.year, today.month, today.day);
      return base.add(
        Duration(days: offset, hours: hour, minutes: minute),
      );
    }

    List<TaskTimelineEntry> timeline(
      List<(String, String, String, DateTime)> rows,
    ) {
      return [
        for (final row in rows)
          TaskTimelineEntry(
            title: row.$1,
            detail: row.$2,
            actor: row.$3,
            timestamp: row.$4,
          ),
      ];
    }

    return switch (user.role) {
      UserRole.employee => [
        TaskItem(
          id: 'emp-1',
          title: 'Asansör test formu',
          project: 'Kuzey Atölye',
          assignee: user.firstName,
          status: TaskStatus.inProgress,
          priority: TaskPriority.medium,
          dueAt: atDay(1, hour: 15),
          updatedAt: atDay(0, hour: 9, minute: 20),
          tag: 'Form',
          description:
              'Saha kontrolünden sonra fotoğraf seti ve test formu birlikte sisteme yüklenecek.',
          checklistCompleted: 3,
          checklistTotal: 5,
          timeline: timeline([
            (
              'Başlatıldı',
              'Saha formu üzerinde çalışmaya başlandı.',
              user.firstName,
              atDay(0, hour: 9, minute: 20),
            ),
            (
              'Yorum eklendi',
              'Eksik fotoğraf açısı için ikinci çekim planlandı.',
              'Seda',
              atDay(-1, hour: 17, minute: 45),
            ),
          ]),
        ),
        TaskItem(
          id: 'emp-2',
          title: 'Yangın pompa kontrolü',
          project: 'Merkez Plaza',
          assignee: user.firstName,
          status: TaskStatus.pending,
          priority: TaskPriority.high,
          dueAt: atDay(0, hour: 17),
          updatedAt: atDay(0, hour: 8, minute: 10),
          tag: 'Kontrol',
          description:
              'Pompa basınç değerleri, vana kontrolü ve pano fotoğrafı aynı teslim paketinde olmalı.',
          checklistCompleted: 1,
          checklistTotal: 4,
          timeline: timeline([
            (
              'Görev atandı',
              'Görev lider onayıyla öncelikli iş listesine alındı.',
              'Sistem',
              atDay(0, hour: 8, minute: 10),
            ),
          ]),
        ),
        TaskItem(
          id: 'emp-3',
          title: 'Klima saha fotoğrafı',
          project: 'Nova Residence',
          assignee: user.firstName,
          status: TaskStatus.revision,
          priority: TaskPriority.low,
          dueAt: atDay(2, hour: 14),
          updatedAt: atDay(-1, hour: 17, minute: 45),
          tag: 'Revizyon',
          description:
              'Revizyon notunda istenen açıya göre dış ünite ve etiket yakın planı yeniden çekilecek.',
          checklistCompleted: 2,
          checklistTotal: 4,
          timeline: timeline([
            (
              'Revizyona düştü',
              'Yakın plan fotoğraf tekrar istendi.',
              'Seda',
              atDay(-1, hour: 17, minute: 45),
            ),
          ]),
        ),
      ],
      UserRole.teamLead => [
        TaskItem(
          id: 'lead-1',
          title: 'Jeneratör periyodik kontrol',
          project: 'Merkez Plaza',
          assignee: 'Onur',
          status: TaskStatus.inProgress,
          priority: TaskPriority.high,
          dueAt: atDay(1, hour: 11),
          updatedAt: atDay(0, hour: 9, minute: 14),
          tag: 'Saha',
          description:
              'Lider onayı öncesi bakım notu, yakıt seviyesi ve panel görseli tamamlanmalı.',
          checklistCompleted: 4,
          checklistTotal: 6,
          timeline: timeline([
            (
              'Başlatıldı',
              'Teknisyen saha kontrolüne çıktı.',
              'Onur',
              atDay(0, hour: 9, minute: 14),
            ),
            (
              'Toplantı notu',
              'Yedek ekip planı için kısa çağrı açıldı.',
              'Seda',
              atDay(-1, hour: 18, minute: 20),
            ),
          ]),
        ),
        TaskItem(
          id: 'lead-2',
          title: 'Yangın paneli raporu',
          project: 'Nova Residence',
          assignee: 'Burak',
          status: TaskStatus.pending,
          priority: TaskPriority.medium,
          dueAt: atDay(0, hour: 16),
          updatedAt: atDay(0, hour: 8, minute: 5),
          tag: 'Rapor',
          description:
              'Rapor teslimi öncesi panel log çıktısı ve saha yorumu eklenmeli.',
          checklistCompleted: 2,
          checklistTotal: 5,
          timeline: timeline([
            (
              'Görev atandı',
              'Rapor paketi ekip lideri kuyruğuna alındı.',
              'Sistem',
              atDay(0, hour: 8, minute: 5),
            ),
          ]),
        ),
        TaskItem(
          id: 'lead-3',
          title: 'Asansör test formu',
          project: 'Kuzey Atölye',
          assignee: 'Ece',
          status: TaskStatus.inReview,
          priority: TaskPriority.low,
          dueAt: atDay(2, hour: 12),
          updatedAt: atDay(-1, hour: 18, minute: 40),
          tag: 'Form',
          description:
              'Teslimden önce güvenlik maddeleri ve form imzası tekrar kontrol edilecek.',
          checklistCompleted: 5,
          checklistTotal: 5,
          timeline: timeline([
            (
              'Teslim edildi',
              'Görev lider incelemesine gönderildi.',
              'Ece',
              atDay(-1, hour: 18, minute: 40),
            ),
          ]),
        ),
        TaskItem(
          id: 'lead-4',
          title: 'UPS kapasite notu',
          project: 'Kuzey Atölye',
          assignee: 'Ece',
          status: TaskStatus.revision,
          priority: TaskPriority.high,
          dueAt: atDay(-1, hour: 13),
          updatedAt: atDay(0, hour: 10, minute: 5),
          tag: 'Etiket',
          description:
              'Revizyon notuna göre kapasite etiketi okunaklı fotoğraf ve açıklama notu bekleniyor.',
          checklistCompleted: 1,
          checklistTotal: 3,
          timeline: timeline([
            (
              'Revizyon istendi',
              'Kapasite etiketi net değil, tekrar çekim bekleniyor.',
              'Seda',
              atDay(0, hour: 10, minute: 5),
            ),
          ]),
        ),
      ],
      UserRole.manager => [
        TaskItem(
          id: 'mgr-1',
          title: 'Jeneratör periyodik kontrol',
          project: 'Merkez Plaza',
          assignee: 'Merve',
          status: TaskStatus.inProgress,
          priority: TaskPriority.high,
          dueAt: atDay(1, hour: 11),
          updatedAt: atDay(0, hour: 9, minute: 14),
          tag: 'Saha',
          description:
              'Operasyon özetine girecek bakım notu ve fotoğraflar teslim öncesi tamamlanmalı.',
          checklistCompleted: 4,
          checklistTotal: 6,
          timeline: timeline([
            (
              'Başlatıldı',
              'Saha ekibi görev üzerinde çalışıyor.',
              'Merve',
              atDay(0, hour: 9, minute: 14),
            ),
          ]),
        ),
        TaskItem(
          id: 'mgr-2',
          title: 'Yangın paneli raporu',
          project: 'Nova Residence',
          assignee: 'Seda',
          status: TaskStatus.pending,
          priority: TaskPriority.medium,
          dueAt: atDay(0, hour: 16),
          updatedAt: atDay(0, hour: 8, minute: 5),
          tag: 'Rapor',
          description:
              'Yönetici görünümünde rapor paketi bekleyen onaylar için izleniyor.',
          checklistCompleted: 2,
          checklistTotal: 5,
          timeline: timeline([
            (
              'Görev atandı',
              'Görev sabah vardiyasında oluşturuldu.',
              'Sistem',
              atDay(0, hour: 8, minute: 5),
            ),
          ]),
        ),
        TaskItem(
          id: 'mgr-3',
          title: 'Asansör test formu',
          project: 'Kuzey Atölye',
          assignee: 'Onur',
          status: TaskStatus.inReview,
          priority: TaskPriority.low,
          dueAt: atDay(2, hour: 12),
          updatedAt: atDay(-1, hour: 18, minute: 40),
          tag: 'Form',
          description:
              'İnceleme kuyruğundaki form paketi tamamlandı, nihai karar bekliyor.',
          checklistCompleted: 5,
          checklistTotal: 5,
          timeline: timeline([
            (
              'Teslim edildi',
              'Görev lideri incelemesine gönderildi.',
              'Onur',
              atDay(-1, hour: 18, minute: 40),
            ),
          ]),
        ),
        TaskItem(
          id: 'mgr-4',
          title: 'Kamera altyapısı',
          project: 'Merkez Plaza',
          assignee: 'Seda',
          status: TaskStatus.revision,
          priority: TaskPriority.high,
          dueAt: atDay(-1, hour: 15),
          updatedAt: atDay(0, hour: 10, minute: 25),
          tag: 'Toplantı',
          description:
              'Toplantı çıktısı göreve bağlanacak ve revizyon sonrası yeni plan paylaşılacak.',
          checklistCompleted: 3,
          checklistTotal: 6,
          timeline: timeline([
            (
              'Revizyon istendi',
              'Kablo rotası ve toplantı notu yeniden bekleniyor.',
              'Merve',
              atDay(0, hour: 10, minute: 25),
            ),
          ]),
        ),
      ],
    };
  }
}
