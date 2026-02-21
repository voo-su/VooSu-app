import 'package:voosu/domain/repositories/chat_repository.dart';

class DeleteChatUseCase {
  final ChatRepository repo;

  DeleteChatUseCase(this.repo);

  Future<void> call({required int peerUserId}) => repo.deleteChat(peerUserId: peerUserId);
}
