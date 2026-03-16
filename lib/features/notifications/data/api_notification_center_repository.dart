import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/features/notifications/data/notification_center_repository.dart';
import 'package:servis_kontrol/features/notifications/domain/workflow_notification.dart';

class ApiNotificationCenterRepository implements NotificationCenterRepository {
  const ApiNotificationCenterRepository(this._client);

  final ApiClient _client;

  @override
  Future<NotificationCenterSnapshot> loadInbox() async {
    final payload = await _client.getMap('notifications');
    return NotificationCenterSnapshot.fromJson(payload);
  }

  @override
  Future<int> markAllRead() async {
    final payload = await _client.postMap('notifications/read-all');
    return payload['unread_count'] as int? ?? 0;
  }

  @override
  Future<int> markRead(String notificationId) async {
    final payload = await _client.postMap('notifications/$notificationId/read');
    return payload['unread_count'] as int? ?? 0;
  }
}
