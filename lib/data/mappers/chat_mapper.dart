import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/user.dart';
import 'package:voosu/generated/grpc_pb/chat.pbgrpc.dart' as chatpb;
import 'package:voosu/generated/grpc_pb/common.pb.dart' as commonpb;

class ChatMapper {
  static Chat fromProto(chatpb.Chat chat, {User? user}) {
    final peer = chat.peer;
    if (peer.whichPeer() != commonpb.Peer_Peer.userId) {
      throw StateError('');
    }

    final peerUserId = peer.userId.toInt();
    String title;
    String userUsername = '';
    String userName = '';
    String userSurname = '';
    if (user != null) {
      title = user.username.isNotEmpty
          ? user.username
          : '${user.name} ${user.surname}'.trim();
      userUsername = user.username;
      userName = user.name;
      userSurname = user.surname;
    } else {
      title = '';
    }

    String? lastMessagePreview;
    if (chat.hasLastMessage() && chat.lastMessage.content.isNotEmpty) {
      const maxLen = 60;
      final content = chat.lastMessage.content.trim();
      lastMessagePreview = content.length <= maxLen
        ? content
        : content.substring(0, maxLen);
    } else if (chat.hasLastMessage() && chat.lastMessage.attachments.isNotEmpty) {
      lastMessagePreview = 'Вложение';
    }

    return Chat(
      id: peerUserId,
      peerUserId: peerUserId,
      title: title,
      userUsername: userUsername,
      userName: userName,
      userSurname: userSurname,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        chat.updatedAt.toInt() * 1000,
      ),
      unreadCount: chat.unreadCount,
      avatarFileId: null,
      lastMessagePreview: lastMessagePreview,
    );
  }

  static List<Chat> listFromProto(
    Iterable<chatpb.Chat> chats,
    Map<int, User> userById,
  ) {
    return chats
        .where((c) => c.peer.whichPeer() == commonpb.Peer_Peer.userId)
        .map((c) {
          final uid = c.peer.userId.toInt();
          return fromProto(c, user: userById[uid]);
        })
        .toList();
  }
}
