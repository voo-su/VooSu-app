import 'package:voosu/domain/repositories/chat_repository.dart';

class RemovePendingMessageUseCase {
  final ChatRepository repo;

  RemovePendingMessageUseCase(this.repo);

  Future<void> call(String localId) => repo.removePendingMessage(localId);
}
