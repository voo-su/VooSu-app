import 'package:voosu/domain/repositories/chat_repository.dart';

class SendChatTypingUseCase {
  final ChatRepository repo;

  SendChatTypingUseCase(this.repo);

  Future<void> call({int? peerUserId, int? peerGroupId}) =>
      repo.sendTyping(peerUserId: peerUserId, peerGroupId: peerGroupId);
}
