import 'package:voosu/domain/entities/attachment_upload.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class SendChatMessageUseCase {
  final ChatRepository repo;

  SendChatMessageUseCase(this.repo);

  Future<Message> call({
    int? peerUserId,
    int? peerGroupId,
    required String content,
    int replyToMessageId = 0,
    bool forwarded = false,
    int forwardedFromMessageId = 0,
    List<AttachmentUpload>? attachments,
  }) => repo.sendMessage(
    peerUserId: peerUserId,
    peerGroupId: peerGroupId,
    content: content,
    replyToMessageId: replyToMessageId,
    forwarded: forwarded,
    forwardedFromMessageId: forwardedFromMessageId,
    attachments: attachments,
  );
}
