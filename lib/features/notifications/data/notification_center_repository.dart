import 'package:servis_kontrol/features/notifications/domain/workflow_notification.dart';

abstract class NotificationCenterRepository {
  Future<NotificationCenterSnapshot> loadInbox();

  Future<int> markRead(String notificationId);

  Future<int> markAllRead();
}
