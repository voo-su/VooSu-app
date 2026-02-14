import 'package:voosu/domain/entities/chat_attachment.dart';

class Message {
  final int id;
  final int peerUserId;
  final int fromPeerUserId;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final int replyToMessageId;
  final bool forwarded;
  final int forwardedFromMessageId;
  final bool replyToMessageDeleted;
  final bool forwardedFromMessageDeleted;
  final List<ChatAttachment> attachments;

  Message({
    required this.id,
    this.peerUserId = 0,
    required this.fromPeerUserId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.replyToMessageId = 0,
    this.forwarded = false,
    this.forwardedFromMessageId = 0,
    this.replyToMessageDeleted = false,
    this.forwardedFromMessageDeleted = false,
    this.attachments = const [],
  });

  int get senderId => fromPeerUserId;

  bool get isSystemMessage => fromPeerUserId == 0;

  bool get hasReply => replyToMessageId > 0;

  bool isInDialog(int myUserId, int otherUserId) {
    return (peerUserId == myUserId && fromPeerUserId == otherUserId)
      || (peerUserId == otherUserId && fromPeerUserId == myUserId);
  }

  Message copyWith({bool? isRead}) {
    return Message(
      id: id,
      peerUserId: peerUserId,
      fromPeerUserId: fromPeerUserId,
      content: content,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      replyToMessageId: replyToMessageId,
      forwarded: forwarded,
      forwardedFromMessageId: forwardedFromMessageId,
      replyToMessageDeleted: replyToMessageDeleted,
      forwardedFromMessageDeleted: forwardedFromMessageDeleted,
      attachments: attachments,
    );
  }
}
