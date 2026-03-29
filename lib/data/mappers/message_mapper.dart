import 'package:voosu/domain/entities/chat_attachment.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/entities/poll.dart';
import 'package:voosu/domain/entities/reply_markup.dart';
import 'package:voosu/generated/grpc_pb/chat.pb.dart' as chatpb;
import 'package:voosu/generated/grpc_pb/common.pb.dart' as commonpb;

class MessageMapper {
  static Message fromProto(chatpb.Message msg) {
    final peer = msg.peer;
    final isGroup = peer.whichPeer() == commonpb.Peer_Peer.groupId;
    final peerUserId = peer.hasUserId() ? peer.userId.toInt() : 0;
    final peerGroupId = peer.hasGroupId() ? peer.groupId.toInt() : 0;
    final fromUserId = msg.fromPeer.hasUserId() ? msg.fromPeer.userId.toInt() : 0;
    final attachments = msg.attachments
      .map((a) => _attachmentFromProto(a))
      .toList();
    final replyMarkup = msg.hasReplyMarkup() ? _replyMarkupFromProto(msg.replyMarkup) : null;
    final poll = msg.hasPoll() ? _pollFromProto(msg.poll) : null;

    final code = msg.hasCode() ? msg.code : null;
    final loc = msg.hasLocation() ? msg.location : null;

    final extraJson = msg.hasExtraJson() && msg.extraJson.isNotEmpty
        ? msg.extraJson
        : null;

    return Message(
      id: msg.id.toInt(),
      isGroupChat: isGroup,
      peerUserId: peerUserId,
      peerGroupId: peerGroupId,
      fromPeerUserId: fromUserId,
      msgType: msg.msgType,
      codeLang: code?.lang,
      codeText: code?.text,
      locationLatitude: loc?.latitude,
      locationLongitude: loc?.longitude,
      locationDescription: loc?.description,
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
      replyMarkup: replyMarkup,
      poll: poll,
      extraJson: extraJson,
    );
  }

  static Poll _pollFromProto(chatpb.Poll p) {
    final options = p.options.map((o) => PollOptionResult(
      optionId: o.optionId.toInt(),
      text: o.text,
      position: o.position.toInt(),
      voteCount: o.voteCount.toInt(),
      voterUserIds: o.voterUserIds.map((id) => id.toInt()).toList(),
    )).toList();

    return Poll(
      id: p.id.toInt(),
      question: p.question,
      anonymous: p.anonymous,
      options: options,
    );
  }

  static ReplyMarkup? _replyMarkupFromProto(chatpb.ReplyMarkup p) {
    if (p.inlineKeyboard.isEmpty) {
      return null;
    }

    final rows = p.inlineKeyboard.map((row) {
      final buttons = row.buttons.map((b) => InlineKeyboardButton(
        text: b.text,
        callbackData: b.callbackData,
      )).toList();
      return InlineKeyboardRow(buttons: buttons);
    }).toList();

    return ReplyMarkup(inlineKeyboard: rows);
  }

  static ChatAttachment _attachmentFromProto(chatpb.ChatAttachment a) {
    switch (a.whichAttachment()) {
      case chatpb.ChatAttachment_Attachment.image:
        final img = a.image;
        final ext = img.externalUrl;
        return ChatAttachment(
          fileId: img.fileId.toInt(),
          filename: img.filename,
          mimeType: img.mimeType,
          size: img.size.toInt(),
          type: 1,
          externalUrl: ext.isNotEmpty ? ext : null,
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
