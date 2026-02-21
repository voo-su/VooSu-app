import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class CreateChatUseCase {
  final ChatRepository repo;

  CreateChatUseCase(this.repo);

  Future<Chat> call(int userId) => repo.createChat(userId);
}
