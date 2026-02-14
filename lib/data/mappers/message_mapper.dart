import 'package:voosu/domain/entities/chat_attachment.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/generated/grpc_pb/chat.pb.dart' as chatpb;

class MessageMapper {
  static Message fromProto(chatpb.Message msg) {
    final peer = msg.peer;
    final peerUserId = peer.hasUserId() ? peer.userId.toInt() : 0;
    final fromUserId = msg.fromPeer.hasUserId() ? msg.fromPeer.userId.toInt() : 0;
    final attachments = msg.attachments
      .map((a) => _attachmentFromProto(a))
      .toList();

    return Message(
      id: msg.id.toInt(),
      peerUserId: peerUserId,
      fromPeerUserId: fromUserId,
      content: msg.content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        msg.createdAt.toInt() * 1000,
      ),
      isRead: msg.isRead,
      replyToMessageId: msg.replyToMessageId.toInt(),
      forwarded: msg.forwarded,
      forwardedFromMessageId: msg.forwardedFromMessageId.toInt(),
      replyToMessageDeleted: msg.replyToMessageDeleted,
      forwardedFromMessageDeleted: msg.forwardedFromMessageDeleted,
      attachments: attachments,
    );
  }

  static ChatAttachment _attachmentFromProto(chatpb.ChatAttachment a) {
    switch (a.whichAttachment()) {
      case chatpb.ChatAttachment_Attachment.image:
        final img = a.image;
        return ChatAttachment(
          fileId: img.fileId.toInt(),
          filename: img.filename,
          mimeType: img.mimeType,
          size: img.size.toInt(),
          type: 1,
        );
      case chatpb.ChatAttachment_Attachment.document:
        final doc = a.document;
        return ChatAttachment(
          fileId: doc.fileId.toInt(),
          filename: doc.filename,
          mimeType: doc.mimeType,
          size: doc.size.toInt(),
          type: 2,
        );
      case chatpb.ChatAttachment_Attachment.video:
        final vid = a.video;
        return ChatAttachment(
          fileId: vid.fileId.toInt(),
          filename: vid.filename,
          mimeType: vid.mimeType,
          size: vid.size.toInt(),
          type: 3,
        );
      case chatpb.ChatAttachment_Attachment.audio:
        final aud = a.audio;
        return ChatAttachment(
          fileId: aud.fileId.toInt(),
          filename: aud.filename,
          mimeType: aud.mimeType,
          size: aud.size.toInt(),
          type: 4,
        );
      case chatpb.ChatAttachment_Attachment.notSet:
        return const ChatAttachment(
          fileId: 0,
          filename: '',
          mimeType: '',
          size: 0,
          type: 0,
        );
    }
  }

  static List<Message> listFromProto(Iterable<chatpb.Message> messages) {
    return messages.map(fromProto).toList();
  }
}
