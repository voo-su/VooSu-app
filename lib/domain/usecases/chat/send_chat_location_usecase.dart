import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class SendChatLocationUseCase {
  final ChatRepository _repo;

  SendChatLocationUseCase(this._repo);

  Future<Message> call({
    required String latitude,
    required String longitude,
    String description = '',
    int? peerUserId,
    int? peerGroupId,
    int replyToMessageId = 0,
  }) => _repo.sendLocationMessage(
    peerUserId: peerUserId,
    peerGroupId: peerGroupId,
    latitude: latitude,
    longitude: longitude,
    description: description,
    replyToMessageId: replyToMessageId,
  );
}
