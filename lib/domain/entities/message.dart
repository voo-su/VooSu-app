import 'package:voosu/core/attachment_type_helper.dart';
import 'package:voosu/core/chat_msg_type.dart';
import 'package:voosu/domain/entities/chat_attachment.dart';
import 'package:voosu/domain/entities/poll.dart';
import 'package:voosu/domain/entities/reply_markup.dart';

class Message {
  final int id;
  final bool isGroupChat;
  final int peerUserId;
  final int peerGroupId;
  final int fromPeerUserId;
  final int msgType;
  final String? codeLang;
  final String? codeText;
  final String? locationLatitude;
  final String? locationLongitude;
  final String? locationDescription;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final int replyToMessageId;
  final bool forwarded;
  final int forwardedFromMessageId;
  final bool replyToMessageDeleted;
  final bool forwardedFromMessageDeleted;
  final List<ChatAttachment> attachments;
  final ReplyMarkup? replyMarkup;
  final Poll? poll;
  final String? extraJson;

  Message({
    required this.id,
    this.isGroupChat = false,
    this.peerUserId = 0,
    this.peerGroupId = 0,
    required this.fromPeerUserId,
    this.msgType = 0,
    this.codeLang,
    this.codeText,
    this.locationLatitude,
    this.locationLongitude,
    this.locationDescription,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.replyToMessageId = 0,
    this.forwarded = false,
    this.forwardedFromMessageId = 0,
    this.replyToMessageDeleted = false,
    this.forwardedFromMessageDeleted = false,
    this.attachments = const [],
    this.replyMarkup,
    this.poll,
    this.extraJson,
  });

  int get senderId => fromPeerUserId;

  String? get plainCopyText {
    if (msgType == 2 && codeText != null && codeText!.trim().isNotEmpty) {
      return codeText!.trim();
    }

    final t = content.trim();
    return t.isNotEmpty ? t : null;
  }

  bool get isSystemMessage => fromPeerUserId == 0;

  bool get usesSystemRowLayout => msgType >= ChatMsgType.sysMin;

  bool get hasReply => replyToMessageId > 0;
  
  bool get canSaveAsMySticker {
    if (msgType != ChatMsgType.image) {
      return false;
    }
    if (attachments.length != 1) {
      return false;
    }
    return attachments.first.type == AttachmentType.image;
  }

  bool isInDialog(int myUserId, int otherUserId) {
    if (isGroupChat) {
      return false;
    }

    return (peerUserId == myUserId && fromPeerUserId == otherUserId)
      || (peerUserId == otherUserId && fromPeerUserId == myUserId);
  }

  bool isInGroupChat(String groupId) {
    return isGroupChat && peerGroupId.toString() == groupId;
  }

  Message copyWith({bool? isRead, Poll? poll, String? extraJson}) {
    return Message(
      id: id,
      isGroupChat: isGroupChat,
      peerUserId: peerUserId,
      peerGroupId: peerGroupId,
      fromPeerUserId: fromPeerUserId,
      msgType: msgType,
      codeLang: codeLang,
      codeText: codeText,
      locationLatitude: locationLatitude,
      locationLongitude: locationLongitude,
      locationDescription: locationDescription,
      content: content,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      replyToMessageId: replyToMessageId,
      forwarded: forwarded,
      forwardedFromMessageId: forwardedFromMessageId,
      replyToMessageDeleted: replyToMessageDeleted,
      forwardedFromMessageDeleted: forwardedFromMessageDeleted,
      attachments: attachments,
      replyMarkup: replyMarkup,
      poll: poll ?? this.poll,
      extraJson: extraJson ?? this.extraJson,
    );
  }
}
