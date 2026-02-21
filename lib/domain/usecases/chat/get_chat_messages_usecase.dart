import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class GetChatMessagesUseCase {
  final ChatRepository repo;

  GetChatMessagesUseCase(this.repo);

  Future<List<Message>> call({
    required int peerUserId,
    required int messageId,
    required int limit,
  }) => repo.getHistory(
    peerUserId: peerUserId,
    messageId: messageId,
    limit: limit,
  );
}
