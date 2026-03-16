import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/features/notifications/application/notification_center_controller.dart';
import 'package:servis_kontrol/features/notifications/data/notification_center_repository.dart';
import 'package:servis_kontrol/features/notifications/domain/workflow_notification.dart';

import '../../../support/test_support.dart';

void main() {
  test('bildirim merkezi yukler ve okundu isaretler', () async {
    final controller = NotificationCenterController(
      apiClient: createTestApiClient(),
      repository: _FakeNotificationCenterRepository(),
      enablePolling: false,
    );

    await controller.load();
    expect(controller.unreadCount, 2);
    expect(controller.items, hasLength(2));

    await controller.markRead('n1');
    expect(controller.unreadCount, 1);
    expect(controller.items.first.isRead, isTrue);

    await controller.markAllRead();
    expect(controller.unreadCount, 0);
    expect(controller.items.every((item) => item.isRead), isTrue);
  });
}

class _FakeNotificationCenterRepository implements NotificationCenterRepository {
  List<WorkflowNotification> _items = [
    WorkflowNotification(
      id: 'n1',
      title: 'Yeni gorev atandi',
      body: 'WF-1001 gorevi size atandi.',
      type: 'task_assigned',
      accentKey: 'primary',
      relatedTaskId: '1',
      relatedRevisionId: null,
      isRead: false,
      createdAt: DateTime(2026, 3, 16, 10),
      createdAtLabel: '10:00',
    ),
    WorkflowNotification(
      id: 'n2',
      title: 'Revizyon istendi',
      body: 'WF-1001 gorevi icin revizyon talebi acildi.',
      type: 'revision_requested',
      accentKey: 'warning',
      relatedTaskId: '1',
      relatedRevisionId: '9',
      isRead: false,
      createdAt: DateTime(2026, 3, 16, 11),
      createdAtLabel: '11:00',
    ),
  ];

  @override
  Future<NotificationCenterSnapshot> loadInbox() async {
    return NotificationCenterSnapshot(
      unreadCount: _items.where((item) => !item.isRead).length,
      items: _items,
    );
  }

  @override
  Future<int> markAllRead() async {
    _items = _items.map((item) => item.copyWith(isRead: true)).toList();
    return 0;
  }

  @override
  Future<int> markRead(String notificationId) async {
    _items = _items
        .map(
          (item) =>
              item.id == notificationId ? item.copyWith(isRead: true) : item,
        )
        .toList();
    return _items.where((item) => !item.isRead).length;
  }
}
