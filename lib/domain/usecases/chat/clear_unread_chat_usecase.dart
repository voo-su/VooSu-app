import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class ClearUnreadChatUseCase {
  final ChatRepository _repo;

  ClearUnreadChatUseCase(this._repo);

  Future<void> call(Chat chat) => _repo.clearUnread(
        peerUserId: chat.isGroup ? null : chat.peerUserId,
        peerGroupId: chat.isGroup ? chat.peerGroupId : null,
      );
}
