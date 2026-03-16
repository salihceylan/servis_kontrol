import 'package:servis_kontrol/features/operations_messages/domain/operation_message_thread.dart';

abstract class OperationMessageRepository {
  Future<OperationMessageInboxSnapshot> loadInbox();

  Future<OperationMessageThread> openThread(String counterpartUserId);

  Future<OperationMessageThread> openBroadcastThread(String targetId);

  Future<OperationMessageThread> loadThread(String threadId);

  Future<OperationMessageThread> sendMessage({
    required String threadId,
    required String body,
  });

  Future<void> markRead(String threadId);
}
