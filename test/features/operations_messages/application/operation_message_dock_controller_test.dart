import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/features/operations_messages/application/operation_message_dock_controller.dart';
import 'package:servis_kontrol/features/operations_messages/data/operation_message_repository.dart';
import 'package:servis_kontrol/features/operations_messages/domain/operation_message_thread.dart';

import '../../../support/test_support.dart';

void main() {
  test('manager operasyon thread acip mesaj gonderebilir', () async {
    final controller = OperationMessageDockController(
      user: managerUser,
      apiClient: createTestApiClient(),
      repository: _FakeOperationMessageRepository(),
      enablePolling: false,
    );

    await controller.load();
    expect(controller.contacts, isNotEmpty);
    expect(controller.broadcastTargets, isNotEmpty);
    expect(controller.threads, isNotEmpty);

    await controller.openThreadWithContact(controller.contacts.first);
    expect(controller.selectedThread, isNotNull);

    final success = await controller.sendMessage('Merkez ekip sahaya ciksin.');
    expect(success, isTrue);
    expect(
      controller.selectedThread!.messages.last.body,
      'Merkez ekip sahaya ciksin.',
    );
    expect(controller.selectedThread!.unreadCount, 0);
  });

  test('manager sirket kanali acabilir', () async {
    final controller = OperationMessageDockController(
      user: managerUser,
      apiClient: createTestApiClient(),
      repository: _FakeOperationMessageRepository(),
      enablePolling: false,
    );

    await controller.load();
    await controller.openBroadcastTarget(controller.broadcastTargets.first);

    expect(controller.selectedThread, isNotNull);
    expect(controller.selectedThread!.threadType, 'company_broadcast');
  });
}

class _FakeOperationMessageRepository implements OperationMessageRepository {
  final Map<String, OperationMessageThread> _threads = {
    'thread-1': OperationMessageThread(
      id: 'thread-1',
      title: 'Merkez Operasyon',
      threadType: 'direct',
      channelLabel: 'Direkt hat',
      participantCount: 2,
      counterpartId: 'teamlead-1',
      counterpartName: 'Onur Demir',
      counterpartRole: 'team_lead',
      counterpartRoleLabel: 'Ekip Lideri',
      counterpartTeamName: 'Merkez Ekip',
      lastMessagePreview: 'Saha hazir.',
      unreadCount: 1,
      canReply: true,
      updatedAt: DateTime(2026, 3, 16, 10),
      lastMessageAt: DateTime(2026, 3, 16, 10),
      messages: [
        OperationMessageItem(
          id: 'msg-1',
          senderUserId: 'teamlead-1',
          senderName: 'Onur Demir',
          body: 'Saha hazir.',
          createdAt: DateTime(2026, 3, 16, 10),
          isMine: false,
        ),
      ],
    ),
  };

  final List<OperationMessageContact> _contacts = const [
    OperationMessageContact(
      id: 'teamlead-1',
      name: 'Onur Demir',
      email: 'onur@workflow.local',
      roleCode: 'team_lead',
      roleLabel: 'Ekip Lideri',
      teamName: 'Merkez Ekip',
    ),
  ];

  @override
  Future<OperationMessageInboxSnapshot> loadInbox() async {
    return OperationMessageInboxSnapshot(
      threads: _threads.values.toList(growable: false),
      contacts: _contacts,
      broadcastTargets: const [
        OperationMessageBroadcastTarget(
          id: 'company',
          scopeCode: 'company',
          label: 'Sirket kanali',
          description: 'Tum aktif kullanicilar',
          participantCount: 12,
        ),
      ],
      pollIntervalSeconds: 8,
    );
  }

  @override
  Future<OperationMessageThread> loadThread(String threadId) async {
    final thread = _threads[threadId]!;
    final updated = thread.copyWith(unreadCount: 0);
    _threads[threadId] = updated;
    return updated;
  }

  @override
  Future<void> markRead(String threadId) async {
    final thread = _threads[threadId];
    if (thread != null) {
      _threads[threadId] = thread.copyWith(unreadCount: 0);
    }
  }

  @override
  Future<OperationMessageThread> openThread(String counterpartUserId) async {
    return loadThread('thread-1');
  }

  @override
  Future<OperationMessageThread> openBroadcastThread(String targetId) async {
    final thread = OperationMessageThread(
      id: 'thread-broadcast',
      title: 'Sirket Operasyon Hatti',
      threadType: 'company_broadcast',
      channelLabel: 'Sirket hatti',
      participantCount: 12,
      counterpartId: null,
      counterpartName: 'Sirket Operasyon Hatti',
      counterpartRole: '',
      counterpartRoleLabel: 'Sirket duyurusu',
      counterpartTeamName: '',
      lastMessagePreview: 'Acil bakim bilgisi paylasildi.',
      unreadCount: 0,
      canReply: true,
      updatedAt: DateTime(2026, 3, 16, 11),
      lastMessageAt: DateTime(2026, 3, 16, 11),
      messages: const [],
    );
    _threads[thread.id] = thread;
    return thread;
  }

  @override
  Future<OperationMessageThread> sendMessage({
    required String threadId,
    required String body,
  }) async {
    final thread = _threads[threadId]!;
    final updated = thread.copyWith(
      lastMessagePreview: body,
      unreadCount: 0,
      messages: [
        ...thread.messages,
        OperationMessageItem(
          id: 'msg-2',
          senderUserId: '1',
          senderName: 'Merve Aydin',
          body: body,
          createdAt: DateTime(2026, 3, 16, 10, 5),
          isMine: true,
        ),
      ],
    );
    _threads[threadId] = updated;
    return updated;
  }
}
