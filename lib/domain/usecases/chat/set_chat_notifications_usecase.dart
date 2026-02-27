import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class SetChatNotificationsUseCase {
  final ChatRepository _repo;

  SetChatNotificationsUseCase(this._repo);

  Future<void> call(Chat chat, bool notificationsMuted) => _repo.setChatNotifications(chat, notificationsMuted);
}
