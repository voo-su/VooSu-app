import 'package:voosu/domain/repositories/chat_repository.dart';

class ClearChatHistoryUseCase {
  final ChatRepository repo;

  ClearChatHistoryUseCase(this.repo);

  Future<void> call({required int peerUserId}) => repo.clearHistory(peerUserId: peerUserId);
}
