import 'package:voosu/domain/repositories/chat_repository.dart';

class DeleteChatUseCase {
  final ChatRepository repo;

  DeleteChatUseCase(this.repo);

  Future<void> call({int? peerUserId, int? peerGroupId}) => repo.deleteChat(
    peerUserId: peerUserId,
    peerGroupId: peerGroupId,
  );
}
