import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class SendChatStickerUseCase {
  final ChatRepository _repo;

  SendChatStickerUseCase(this._repo);

  Future<Message> call({
    required int stickerId,
    int? peerUserId,
    int? peerGroupId,
    int replyToMessageId = 0,
  }) =>
      _repo.sendSticker(
        peerUserId: peerUserId,
        peerGroupId: peerGroupId,
        stickerId: stickerId,
        replyToMessageId: replyToMessageId,
      );
}
