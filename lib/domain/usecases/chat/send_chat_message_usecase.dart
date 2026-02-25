import 'package:voosu/domain/entities/attachment_upload.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class SendChatMessageUseCase {
  final ChatRepository repo;

  SendChatMessageUseCase(this.repo);

  Future<Message> call({
    required int peerUserId,
    required String content,
    int replyToMessageId = 0,
    bool forwarded = false,
    int forwardedFromMessageId = 0,
    List<AttachmentUpload>? attachments,
  }) => repo.sendMessage(
    peerUserId: peerUserId,
    content: content,
    replyToMessageId: replyToMessageId,
    forwarded: forwarded,
    forwardedFromMessageId: forwardedFromMessageId,
    attachments: attachments,
  );
}
