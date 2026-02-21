import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class GetChatsUseCase {
  final ChatRepository repo;

  GetChatsUseCase(this.repo);

  Future<List<Chat>> call() => repo.getChats();
}
