import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/user.dart';
import 'package:voosu/generated/grpc_pb/chat.pbgrpc.dart' as chatpb;
import 'package:voosu/generated/grpc_pb/common.pb.dart' as commonpb;

class ChatMapper {
  static Chat fromProto(
    chatpb.Chat chat,
    {
      User? user,
      commonpb.Group? group
    }
  ) {
    final peer = chat.peer;
    final isGroup = peer.whichPeer() == commonpb.Peer_Peer.groupId;
    final peerUserId = peer.hasUserId() ? peer.userId.toInt() : 0;
    final peerGroupId = peer.hasGroupId() ? peer.groupId.toInt() : 0;
    final id = isGroup ? -peerGroupId : peerUserId;
    String title;
    String userUsername = '';
    String userName = '';
    String userSurname = '';
    if (isGroup && group != null) {
      title = group.title;
    } else if (user != null) {
      title = user.username.isNotEmpty
          ? user.username
          : '${user.name} ${user.surname}'.trim();
      userUsername = user.username;
      userName = user.name;
      userSurname = user.surname;
    } else {
      title = isGroup ? 'Группа' : '';
    }

    final memberCount = (isGroup && group != null) ? group.memberCount : 0;
    final avatarFileId = (isGroup && group != null && group.avatarFileId > 0)
      ? group.avatarFileId.toInt()
      : null;

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
      id: id,
      isGroup: isGroup,
      peerUserId: peerUserId,
      peerGroupId: peerGroupId,
      title: title,
      userUsername: userUsername,
      userName: userName,
      userSurname: userSurname,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        chat.updatedAt.toInt() * 1000,
      ),
      unreadCount: chat.unreadCount,
      memberCount: memberCount,
      avatarFileId: avatarFileId,
      lastMessagePreview: lastMessagePreview,
      notificationsMuted: chat.notificationsMuted,
    );
  }

  static List<Chat> listFromProto(
    Iterable<chatpb.Chat> chats,
    Map<int, User> userById,
    Map<int, commonpb.Group> groupById,
  ) {
    return chats.map((c) {
      final isGroup = c.peer.whichPeer() == commonpb.Peer_Peer.groupId;
      User? user;
      commonpb.Group? group;
      if (isGroup) {
        final gid = c.peer.groupId.toInt();
        group = groupById[gid];
      } else {
        final uid = c.peer.userId.toInt();
        user = userById[uid];
      }
      return fromProto(c, user: user, group: group);
    }).toList();
  }
}
