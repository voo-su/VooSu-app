import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class GetChatMessagesUseCase {
  final ChatRepository repo;

  GetChatMessagesUseCase(this.repo);

  Future<List<Message>> call({
    int? peerUserId,
    int? peerGroupId,
    required int messageId,
    required int limit,
  }) => repo.getHistory(
    peerUserId: peerUserId,
    peerGroupId: peerGroupId,
    messageId: messageId,
    limit: limit,
  );

  Future<List<Message>> getCachedMessages(
    int chatId,
    int limit, {
    int? beforeMessageId,
  }) => repo.getCachedMessagesForChat(
    chatId,
    limit,
    beforeMessageId: beforeMessageId,
  );

  Future<bool> hasOlderCachedMessages(
    int chatId,
    int oldestMessageId,
  ) => repo.hasOlderCachedMessages(chatId, oldestMessageId);
}
