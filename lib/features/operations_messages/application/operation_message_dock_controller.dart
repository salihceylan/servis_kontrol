import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/network/api_exception.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/operations_messages/data/api_operation_message_repository.dart';
import 'package:servis_kontrol/features/operations_messages/data/operation_message_repository.dart';
import 'package:servis_kontrol/features/operations_messages/domain/operation_message_thread.dart';

class OperationMessageDockController extends ChangeNotifier {
  OperationMessageDockController({
    required AppUser user,
    required ApiClient apiClient,
    OperationMessageRepository? repository,
    bool enablePolling = true,
  }) : _user = user,
       _repository = repository ?? ApiOperationMessageRepository(apiClient),
       _enablePolling = enablePolling {
    if (shouldShow) {
      load();
    }
  }

  final AppUser _user;
  final OperationMessageRepository _repository;
  final bool _enablePolling;

  List<OperationMessageThread> _threads = const [];
  List<OperationMessageContact> _contacts = const [];
  String? _selectedThreadId;
  bool _isLoading = true;
  bool _isOpen = false;
  bool _isSending = false;
  String? _errorMessage;
  Timer? _pollTimer;
  Duration _pollInterval = const Duration(seconds: 8);

  bool get shouldShow =>
      _user.role == UserRole.manager || _user.role == UserRole.teamLead;
  bool get isLoading => _isLoading;
  bool get isOpen => _isOpen;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  List<OperationMessageThread> get threads => _threads;
  List<OperationMessageContact> get contacts => _contacts;
  int get unreadCount =>
      _threads.fold(0, (total, thread) => total + thread.unreadCount);

  OperationMessageThread? get selectedThread {
    if (_threads.isEmpty) {
      return null;
    }
    if (_selectedThreadId == null) {
      return _threads.first;
    }
    return _threads.cast<OperationMessageThread?>().firstWhere(
      (thread) => thread?.id == _selectedThreadId,
      orElse: () => _threads.first,
    );
  }

  Future<void> load() async {
    if (!shouldShow) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final inbox = await _repository.loadInbox();
      _threads = inbox.threads;
      _contacts = inbox.contacts;
      _pollInterval = Duration(seconds: inbox.pollIntervalSeconds);
      _ensureSelection();
      if (_enablePolling) {
        _restartPolling();
      }
      if (_selectedThreadId != null) {
        final thread = await _repository.loadThread(_selectedThreadId!);
        _writeThread(thread);
      }
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Operasyon mesajları alınamadı.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleOpen() {
    _isOpen = !_isOpen;
    notifyListeners();
  }

  Future<void> selectThread(String threadId) async {
    _selectedThreadId = threadId;
    notifyListeners();
    try {
      final thread = await _repository.loadThread(threadId);
      _writeThread(thread);
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Konuşma yüklenemedi.';
      notifyListeners();
    }
  }

  Future<void> openThreadWithContact(OperationMessageContact contact) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final thread = await _repository.openThread(contact.id);
      _writeThread(thread);
      _isOpen = true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Konuşma başlatılamadı.';
    } finally {
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String body) async {
    final thread = selectedThread;
    final normalized = body.trim();
    if (thread == null || normalized.isEmpty) {
      return false;
    }

    _isSending = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await _repository.sendMessage(
        threadId: thread.id,
        body: normalized,
      );
      _writeThread(updated);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Mesaj gönderilemedi.';
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _restartPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      await _refresh();
    });
  }

  Future<void> _refresh() async {
    try {
      final inbox = await _repository.loadInbox();
      _threads = inbox.threads;
      _contacts = inbox.contacts;
      _ensureSelection();
      if (_selectedThreadId != null) {
        final thread = await _repository.loadThread(_selectedThreadId!);
        _writeThread(thread, notify: false);
      }
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      // Polling hataları dock'u kilitlemesin.
    }
  }

  void _ensureSelection() {
    if (_threads.isEmpty) {
      _selectedThreadId = null;
      return;
    }
    final exists = _threads.any((thread) => thread.id == _selectedThreadId);
    if (!exists) {
      _selectedThreadId = _threads.first.id;
    }
  }

  void _writeThread(OperationMessageThread updated, {bool notify = true}) {
    _threads =
        [
          updated.copyWith(unreadCount: 0),
          for (final thread in _threads)
            if (thread.id != updated.id) thread,
        ]..sort((a, b) {
          final left = a.lastMessageAt ?? a.updatedAt ?? DateTime(1970);
          final right = b.lastMessageAt ?? b.updatedAt ?? DateTime(1970);
          return right.compareTo(left);
        });
    _selectedThreadId = updated.id;
    if (notify) {
      notifyListeners();
    }
  }
}
