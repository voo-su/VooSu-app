import 'package:voosu/domain/entities/attachment_upload.dart';
import 'package:voosu/domain/entities/group_message_mention.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/entities/mixed_send_item.dart';
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
    GroupMessageMention? mention,
  }) async {
    if (forwarded ||
        forwardedFromMessageId != 0 ||
        !shouldSendAsMixedMessage(content, attachments)) {
      return repo.sendMessage(
        peerUserId: peerUserId,
        peerGroupId: peerGroupId,
        content: content,
        replyToMessageId: replyToMessageId,
        forwarded: forwarded,
        forwardedFromMessageId: forwardedFromMessageId,
        attachments: attachments,
        mention: mention,
      );
    }

    final text = content.trim();
    final imgs = attachments!;
    final items = <MixedSendItem>[
      MixedSendItem(itemType: 1, content: text, imageFileId: ''),
      ...imgs.map(
        (a) => MixedSendItem(itemType: 3, content: '', imageFileId: a.fileId),
      ),
    ];
    return repo.sendMixedMessage(
      peerUserId: peerUserId,
      peerGroupId: peerGroupId,
      items: items,
      replyToMessageId: replyToMessageId,
      mention: mention,
    );
  }
}
