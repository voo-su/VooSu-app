import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class CreateGroupChatUseCase {
  final ChatRepository repo;

  CreateGroupChatUseCase(this.repo);

  Future<Chat> call({
    required String title,
    required List<int> userIds,
  }) => repo.createGroupChat(title: title, userIds: userIds);
}
