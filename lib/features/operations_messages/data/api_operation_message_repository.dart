import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/features/operations_messages/data/operation_message_repository.dart';
import 'package:servis_kontrol/features/operations_messages/domain/operation_message_thread.dart';

class ApiOperationMessageRepository implements OperationMessageRepository {
  const ApiOperationMessageRepository(this._client);

  final ApiClient _client;

  @override
  Future<OperationMessageInboxSnapshot> loadInbox() async {
    final payload = await _client.getMap('operations/messages');
    return OperationMessageInboxSnapshot.fromJson(payload);
  }

  @override
  Future<OperationMessageThread> loadThread(String threadId) async {
    final payload = await _client.getMap(
      'operations/messages/threads/$threadId',
    );
    return OperationMessageThread.fromJson(
      payload['thread'] as Map<String, dynamic>? ?? payload,
    );
  }

  @override
  Future<void> markRead(String threadId) async {
    await _client.postVoid('operations/messages/threads/$threadId/read');
  }

  @override
  Future<OperationMessageThread> openThread(String counterpartUserId) async {
    final payload = await _client.postMap(
      'operations/messages/threads/open',
      body: {'counterpart_user_id': counterpartUserId},
    );
    return OperationMessageThread.fromJson(
      payload['thread'] as Map<String, dynamic>? ?? payload,
    );
  }

  @override
  Future<OperationMessageThread> sendMessage({
    required String threadId,
    required String body,
  }) async {
    final payload = await _client.postMap(
      'operations/messages/threads/$threadId/messages',
      body: {'body': body},
    );
    return OperationMessageThread.fromJson(
      payload['thread'] as Map<String, dynamic>? ?? payload,
    );
  }
}
