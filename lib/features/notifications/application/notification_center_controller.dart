import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/network/api_exception.dart';
import 'package:servis_kontrol/features/notifications/data/api_notification_center_repository.dart';
import 'package:servis_kontrol/features/notifications/data/notification_center_repository.dart';
import 'package:servis_kontrol/features/notifications/domain/workflow_notification.dart';

class NotificationCenterController extends ChangeNotifier {
  NotificationCenterController({
    required ApiClient apiClient,
    NotificationCenterRepository? repository,
    bool enablePolling = true,
  }) : _repository = repository ?? ApiNotificationCenterRepository(apiClient),
       _enablePolling = enablePolling {
    load();
  }

  final NotificationCenterRepository _repository;
  final bool _enablePolling;

  List<WorkflowNotification> _items = const [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollTimer;

  List<WorkflowNotification> get items => _items;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _repository.loadInbox();
      _items = snapshot.items;
      _unreadCount = snapshot.unreadCount;
      _errorMessage = null;
      if (_enablePolling) {
        _restartPolling();
      }
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Bildirimler alinamadi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String notificationId) async {
    try {
      _unreadCount = await _repository.markRead(notificationId);
      _items = _items
          .map(
            (item) => item.id == notificationId ? item.copyWith(isRead: true) : item,
          )
          .toList(growable: false);
      notifyListeners();
    } catch (_) {
      // Kullanici akisini bozmasin.
    }
  }

  Future<void> markAllRead() async {
    try {
      _unreadCount = await _repository.markAllRead();
      _items = _items
          .map((item) => item.isRead ? item : item.copyWith(isRead: true))
          .toList(growable: false);
      notifyListeners();
    } catch (_) {
      // Kullanici akisini bozmasin.
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _restartPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) async {
      try {
        final snapshot = await _repository.loadInbox();
        _items = snapshot.items;
        _unreadCount = snapshot.unreadCount;
        _errorMessage = null;
        notifyListeners();
      } catch (_) {
        // Polling sessizce devam etsin.
      }
    });
  }
}
