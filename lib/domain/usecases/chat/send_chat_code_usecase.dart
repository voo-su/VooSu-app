import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class SendChatCodeUseCase {
  final ChatRepository _repo;

  SendChatCodeUseCase(this._repo);

  Future<Message> call({
    required String lang,
    required String code,
    int? peerUserId,
    int? peerGroupId,
    int replyToMessageId = 0,
  }) => _repo.sendCodeMessage(
    peerUserId: peerUserId,
    peerGroupId: peerGroupId,
    lang: lang,
    code: code,
    replyToMessageId: replyToMessageId,
  );
}
