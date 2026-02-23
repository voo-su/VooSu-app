import 'package:voosu/domain/entities/attachment_upload.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class SendChatMessageUseCase {
  final ChatRepository repo;

  SendChatMessageUseCase(this.repo);

  Future<Message> call({
    required int peerUserId,
    required String content,
    List<AttachmentUpload>? attachments,
  }) => repo.sendMessage(
    peerUserId: peerUserId,
    content: content,
    attachments: attachments,
  );
}
