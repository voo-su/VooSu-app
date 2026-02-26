import 'package:voosu/domain/entities/chat_attachment.dart';
import 'package:voosu/domain/entities/poll.dart';

class Message {
  final int id;
  final bool isGroupChat;
  final int peerUserId;
  final int peerGroupId;
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
  final Poll? poll;

  Message({
    required this.id,
    this.isGroupChat = false,
    this.peerUserId = 0,
    this.peerGroupId = 0,
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
    this.poll,
  });

  int get senderId => fromPeerUserId;

  bool get isSystemMessage => fromPeerUserId == 0;

  bool get hasReply => replyToMessageId > 0;

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

  Message copyWith({bool? isRead, Poll? poll}) {
    return Message(
      id: id,
      isGroupChat: isGroupChat,
      peerUserId: peerUserId,
      peerGroupId: peerGroupId,
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
      poll: poll ?? this.poll,
    );
  }
}
