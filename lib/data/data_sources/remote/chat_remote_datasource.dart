import 'dart:async';
import 'dart:math' as math;

import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:voosu/core/auth_guard.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/grpc_channel_manager.dart';
import 'package:voosu/core/grpc_error_handler.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/mappers/chat_mapper.dart';
import 'package:voosu/data/mappers/message_mapper.dart';
import 'package:voosu/data/mappers/user_mapper.dart';
import 'package:voosu/domain/entities/attachment_upload.dart';
import 'package:voosu/domain/entities/group_message_mention.dart';
import 'package:voosu/domain/entities/mixed_send_item.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/group_info.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/entities/overt_group_listing.dart';
import 'package:voosu/domain/entities/user_sticker.dart';
import 'package:voosu/generated/grpc_pb/chat.pbgrpc.dart' as chatpb;
import 'package:voosu/generated/grpc_pb/common.pb.dart' as commonpb;
import 'package:voosu/generated/grpc_pb/file.pbgrpc.dart' as filepb;

abstract class IChatRemoteDataSource {
  Future<Chat> createChat(int userId);

  Future<Chat> createGroupChat({
    required String title,
    required List<int> userIds,
  });

  Future<List<Chat>> getChats();

  Future<GroupInfo> getGroupInfo(int groupId);

  Future<void> addGroupMembers(int groupId, List<int> userIds);

  Future<void> removeGroupMembers(int groupId, List<int> userIds);

  Future<void> setGroupMemberRole(int groupId, int userId, int role);

  Future<Message> sendMessage({
    int? peerUserId,
    int? peerGroupId,
    required String content,
    int replyToMessageId = 0,
    bool forwarded = false,
    int forwardedFromMessageId = 0,
    List<AttachmentUpload>? attachments,
    GroupMessageMention? mention,
  });

  Future<Message> sendMixedMessage({
    int? peerUserId,
    int? peerGroupId,
    required List<MixedSendItem> items,
    int replyToMessageId = 0,
    GroupMessageMention? mention,
  });

  Future<List<UserSticker>> listMyStickers();

  Future<UserSticker> addStickerFromUploadedFile(int fileId);

  Future<void> deleteMyStickers(List<int> stickerIds);

  Future<void> collectStickerFromMessage(int messageId);

  Future<Message> sendSticker({
    int? peerUserId,
    int? peerGroupId,
    required int stickerId,
    int replyToMessageId = 0,
  });

  Future<Message> sendCodeMessage({
    int? peerUserId,
    int? peerGroupId,
    required String lang,
    required String code,
    int replyToMessageId = 0,
  });

  Future<Message> sendLocationMessage({
    int? peerUserId,
    int? peerGroupId,
    required String latitude,
    required String longitude,
    String description = '',
    int replyToMessageId = 0,
  });

  Future<int> uploadFile({
    required String filename,
    String mimeType = '',
    required Stream<List<int>> chunkStream,
    int? totalBytes,
    void Function(int sentBytes, int? totalBytes)? onProgress,
  });

  Future<List<Message>> getHistory({
    int? peerUserId,
    int? peerGroupId,
    required int messageId,
    required int limit,
  });

  Future<void> deleteMessages(List<int> messageIds, {bool forEveryone = true});

  Future<void> clearHistory({int? peerUserId, int? peerGroupId});

  Future<void> deleteChat({int? peerUserId, int? peerGroupId});

  Future<void> sendTyping({int? peerUserId, int? peerGroupId});

  Future<int> uploadGroupPhoto(int groupId, int fileId);

  Future<void> setChatNotifications(Chat chat, bool notificationsMuted);

  Future<void> setChatTop({required int listId, required bool pin});

  Future<void> leaveGroup(int groupId);

  Future<({List<OvertGroupListing> items, bool hasMore})> searchPublicGroups({
    required String nameQuery,
    required int page,
  });

  Future<void> requestToJoinGroup(int groupId);

  Future<void> clearUnread({int? peerUserId, int? peerGroupId});

  Future<void> reportInlineCallback({
    int? peerUserId,
    int? peerGroupId,
    required int messageId,
    required String callbackData,
  });

  Future<Message> createPoll({
    required int peerGroupId,
    required String question,
    required List<String> options,
    required bool anonymous,
  });

  Future<void> votePoll({
    required int peerGroupId,
    required int messageId,
    required int optionId,
  });
}

class ChatRemoteDataSource implements IChatRemoteDataSource {
  final GrpcChannelManager _channelManager;
  final AuthGuard _authGuard;

  ChatRemoteDataSource(this._channelManager, this._authGuard);

  chatpb.ChatServiceClient get _client => _channelManager.chatClient;
  filepb.FileServiceClient get _fileClient => _channelManager.fileClient;

  @override
  Future<Chat> createChat(int userId) async {
    Logs().d('ChatRemoteDataSource: createChat userId=$userId');
    try {
      final req = chatpb.CreateChatRequest(userId: Int64(userId));
      final resp = await _authGuard.execute(() => _client.createChat(req));

      return ChatMapper.fromProto(resp);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в createChat', e);
      throwGrpcError(e, 'Ошибка открытия чата');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в createChat', e);
      throw ApiFailure('Ошибка открытия чата');
    }
  }

  @override
  Future<Chat> createGroupChat({
    required String title,
    required List<int> userIds,
  }) async {
    Logs().d('ChatRemoteDataSource: createGroupChat title=$title');
    try {
      final req = chatpb.CreateGroupChatRequest(
        title: title,
        userIds: userIds.map((id) => Int64(id)).toList(),
      );
      final resp = await _authGuard.execute(() => _client.createGroupChat(req));
      return ChatMapper.fromProto(
        resp.chat,
        group: resp.hasGroup() ? resp.group : null,
      );
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в createGroupChat', e);
      throwGrpcError(e, 'Ошибка создания группового чата');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в createGroupChat', e);
      throw ApiFailure('Ошибка создания группового чата');
    }
  }

  @override
  Future<List<Chat>> getChats() async {
    Logs().d('ChatRemoteDataSource: getChats');
    try {
      final req = chatpb.GetChatsRequest();
      final resp = await _authGuard.execute(() => _client.getChats(req));

      final users = UserMapper.listFromProto(resp.users);
      final userById = {for (final u in users) u.id: u};
      final groupById = {for (final g in resp.groups) g.id.toInt(): g};
      return ChatMapper.listFromProto(resp.chats, userById, groupById);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в getChats', e);
      throwGrpcError(e, 'Ошибка получения чатов');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в getChats', e);
      throw ApiFailure('Ошибка получения чатов');
    }
  }

  @override
  Future<GroupInfo> getGroupInfo(int groupId) async {
    try {
      final req = chatpb.GetGroupInfoRequest(groupId: Int64(groupId));
      final resp = await _authGuard.execute(() => _client.getGroupInfo(req));
      final members = resp.members.map((m) => GroupMemberInfo(
        userId: m.userId.toInt(),
        role: m.role,
        ))
          .toList();
      final users = UserMapper.listFromProto(resp.users);
      final avatarFileId = resp.group.avatarFileId > 0
        ? resp.group.avatarFileId.toInt()
        : null;
      return GroupInfo(
        id: resp.group.id.toInt(),
        title: resp.group.title,
        memberCount: resp.group.memberCount,
        avatarFileId: avatarFileId,
        members: members,
        users: users,
      );
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в getGroupInfo', e);
      throwGrpcError(e, 'Ошибка загрузки информации о группе');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в getGroupInfo', e);
      throw ApiFailure('Ошибка загрузки информации о группе');
    }
  }

  @override
  Future<void> addGroupMembers(int groupId, List<int> userIds) async {
    try {
      final req = chatpb.AddGroupMembersRequest(
        groupId: Int64(groupId),
        userIds: userIds.map((id) => Int64(id)).toList(),
      );
      await _authGuard.execute(() => _client.addGroupMembers(req));
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в addGroupMembers', e);
      throwGrpcError(e, 'Ошибка добавления участников');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в addGroupMembers', e);
      throw ApiFailure('Ошибка добавления участников');
    }
  }

  @override
  Future<void> removeGroupMembers(int groupId, List<int> userIds) async {
    try {
      final req = chatpb.RemoveGroupMembersRequest(
        groupId: Int64(groupId),
        userIds: userIds.map((id) => Int64(id)).toList(),
      );
      await _authGuard.execute(() => _client.removeGroupMembers(req));
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в removeGroupMembers', e);
      throwGrpcError(e, 'Ошибка удаления участников');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в removeGroupMembers', e);
      throw ApiFailure('Ошибка удаления участников');
    }
  }

  @override
  Future<void> setGroupMemberRole(int groupId, int userId, int role) async {
    try {
      final req = chatpb.SetGroupMemberRoleRequest(
        groupId: Int64(groupId),
        userId: Int64(userId),
        role: role,
      );
      await _authGuard.execute(() => _client.setGroupMemberRole(req));
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в setGroupMemberRole', e);
      throwGrpcError(e, 'Ошибка изменения роли');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в setGroupMemberRole', e);
      throw ApiFailure('Ошибка изменения роли');
    }
  }

  @override
  Future<Message> sendMessage({
    int? peerUserId,
    int? peerGroupId,
    required String content,
    int replyToMessageId = 0,
    bool forwarded = false,
    int forwardedFromMessageId = 0,
    List<AttachmentUpload>? attachments,
    GroupMessageMention? mention,
  }) async {
    Logs().d('ChatRemoteDataSource: sendMessage peerUserId=$peerUserId peerGroupId=$peerGroupId');
    try {
      final peer = peerGroupId != null && peerGroupId > 0
        ? commonpb.Peer(groupId: Int64(peerGroupId))
        : commonpb.Peer(userId: Int64(peerUserId ?? 0));
      final attachmentProtos = (attachments ?? []).map((a) => chatpb.AttachmentUpload(
        filename: a.filename,
        fileId: Int64(a.fileId),
      ))
      .toList();
      final req = chatpb.SendMessageRequest(
        peer: peer,
        content: content,
        replyToMessageId: replyToMessageId > 0 ? Int64(replyToMessageId) : null,
        forwarded: forwarded,
        forwardedFromMessageId: forwardedFromMessageId > 0
          ? Int64(forwardedFromMessageId)
          : null,
        attachments: attachmentProtos,
        mention: mention != null && !mention.isEmpty
            ? chatpb.MessageMention(all: mention.all, uids: mention.uids)
            : null,
      );
      final resp = await _authGuard.execute(() => _client.sendMessage(req));

      return MessageMapper.fromProto(resp);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в sendMessage', e);
      throwGrpcError(e, 'Ошибка отправки сообщения');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в sendMessage', e);
      throw ApiFailure('Ошибка отправки сообщения');
    }
  }

  @override
  Future<Message> sendMixedMessage({
    int? peerUserId,
    int? peerGroupId,
    required List<MixedSendItem> items,
    int replyToMessageId = 0,
    GroupMessageMention? mention,
  }) async {
    try {
      final peer = peerGroupId != null && peerGroupId > 0
        ? commonpb.Peer(groupId: Int64(peerGroupId))
        : commonpb.Peer(userId: Int64(peerUserId ?? 0));
      final protos = items
          .map(
            (e) => chatpb.MixedMessageItem(
              itemType: e.itemType,
              content: e.content,
              imageFileId: e.imageFileId > 0 ? Int64(e.imageFileId) : null,
            ),
          )
          .toList();
      final req = chatpb.SendMessageRequest(
        peer: peer,
        content: '',
        replyToMessageId: replyToMessageId > 0 ? Int64(replyToMessageId) : null,
        mixedItems: protos,
        mention: mention != null && !mention.isEmpty
            ? chatpb.MessageMention(all: mention.all, uids: mention.uids)
            : null,
      );
      final resp = await _authGuard.execute(() => _client.sendMessage(req));
      return MessageMapper.fromProto(resp);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в sendMixedMessage', e);
      throwGrpcError(e, 'Ошибка отправки сообщения');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в sendMixedMessage', e);
      throw ApiFailure('Ошибка отправки сообщения');
    }
  }

  @override
  Future<List<UserSticker>> listMyStickers() async {
    try {
      final resp = await _authGuard.execute(
        () => _client.listMyStickers(chatpb.ListMyStickersRequest()),
      );
      return resp.stickers
          .map((s) => UserSticker(id: s.id.toInt(), url: s.url))
          .toList();
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в listMyStickers', e);
      throwGrpcError(e, 'Ошибка загрузки стикеров');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в listMyStickers', e);
      throw ApiFailure('Ошибка загрузки стикеров');
    }
  }

  @override
  Future<UserSticker> addStickerFromUploadedFile(int fileId) async {
    try {
      final resp = await _authGuard.execute(
        () => _client.addStickerFromFile(
          chatpb.AddStickerFromFileRequest(fileId: Int64(fileId)),
        ),
      );
      return UserSticker(id: resp.id.toInt(), url: resp.url);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в addStickerFromUploadedFile', e);
      throwGrpcError(e, 'Не удалось добавить стикер');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в addStickerFromUploadedFile', e);
      throw ApiFailure('Не удалось добавить стикер');
    }
  }

  @override
  Future<void> deleteMyStickers(List<int> stickerIds) async {
    if (stickerIds.isEmpty) {
      return;
    }
    try {
      await _authGuard.execute(
        () => _client.deleteMyStickers(
          chatpb.DeleteMyStickersRequest(
            stickerIds: stickerIds.map((id) => Int64(id)).toList(),
          ),
        ),
      );
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в deleteMyStickers', e);
      throwGrpcError(e, 'Не удалось удалить стикер');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в deleteMyStickers', e);
      throw ApiFailure('Не удалось удалить стикер');
    }
  }

  @override
  Future<void> collectStickerFromMessage(int messageId) async {
    if (messageId <= 0) {
      throw ApiFailure('Некорректное сообщение');
    }
    try {
      await _authGuard.execute(
        () => _client.collectStickerFromMessage(
          chatpb.CollectStickerFromMessageRequest(messageId: Int64(messageId)),
        ),
      );
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в collectStickerFromMessage', e);
      throwGrpcError(e, 'Не удалось сохранить стикер');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в collectStickerFromMessage', e);
      throw ApiFailure('Не удалось сохранить стикер');
    }
  }

  @override
  Future<Message> sendSticker({
    int? peerUserId,
    int? peerGroupId,
    required int stickerId,
    int replyToMessageId = 0,
  }) async {
    try {
      final peer = peerGroupId != null && peerGroupId > 0
        ? commonpb.Peer(groupId: Int64(peerGroupId))
        : commonpb.Peer(userId: Int64(peerUserId ?? 0));
      final req = chatpb.SendMessageRequest(
        peer: peer,
        stickerId: Int64(stickerId),
        replyToMessageId: replyToMessageId > 0 ? Int64(replyToMessageId) : null,
      );
      final resp = await _authGuard.execute(() => _client.sendMessage(req));
      return MessageMapper.fromProto(resp);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в sendSticker', e);
      throwGrpcError(e, 'Ошибка отправки стикера');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в sendSticker', e);
      throw ApiFailure('Ошибка отправки стикера');
    }
  }

  @override
  Future<Message> sendCodeMessage({
    int? peerUserId,
    int? peerGroupId,
    required String lang,
    required String code,
    int replyToMessageId = 0,
  }) async {
    try {
      final peer = peerGroupId != null && peerGroupId > 0
          ? commonpb.Peer(groupId: Int64(peerGroupId))
          : commonpb.Peer(userId: Int64(peerUserId ?? 0));
      final req = chatpb.SendMessageRequest(
        peer: peer,
        code: chatpb.MessageCode(lang: lang, text: code),
        replyToMessageId: replyToMessageId > 0 ? Int64(replyToMessageId) : null,
      );
      final resp = await _authGuard.execute(() => _client.sendMessage(req));
      return MessageMapper.fromProto(resp);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в sendCodeMessage', e);
      throwGrpcError(e, 'Ошибка отправки кода');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в sendCodeMessage', e);
      throw ApiFailure('Ошибка отправки кода');
    }
  }

  @override
  Future<Message> sendLocationMessage({
    int? peerUserId,
    int? peerGroupId,
    required String latitude,
    required String longitude,
    String description = '',
    int replyToMessageId = 0,
  }) async {
    try {
      final peer = peerGroupId != null && peerGroupId > 0
          ? commonpb.Peer(groupId: Int64(peerGroupId))
          : commonpb.Peer(userId: Int64(peerUserId ?? 0));
      final req = chatpb.SendMessageRequest(
        peer: peer,
        location: chatpb.MessageLocation(
          latitude: latitude,
          longitude: longitude,
          description: description,
        ),
        replyToMessageId: replyToMessageId > 0 ? Int64(replyToMessageId) : null,
      );
      final resp = await _authGuard.execute(() => _client.sendMessage(req));
      return MessageMapper.fromProto(resp);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в sendLocationMessage', e);
      throwGrpcError(e, 'Ошибка отправки местоположения');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в sendLocationMessage', e);
      throw ApiFailure('Ошибка отправки местоположения');
    }
  }

  @override
  Future<int> uploadFile({
    required String filename,
    String mimeType = '',
    required Stream<List<int>> chunkStream,
    int? totalBytes,
    void Function(int sentBytes, int? totalBytes)? onProgress,
  }) async {
    Logs().d('ChatRemoteDataSource: uploadFile filename=$filename');
    try {
      const maxPayload = 2 * 1024 * 1024;
      Stream<filepb.UploadFileRequest> requestStream() async* {
        final meta = filepb.UploadFileMeta(
          filename: filename,
          mimeType: mimeType,
        );
        if (totalBytes != null && totalBytes > 0) {
          meta.totalBytes = Int64(totalBytes);
        }
        yield filepb.UploadFileRequest(meta: meta);
        var partNumber = 1;
        var sent = 0;
        await for (final chunk in chunkStream) {
          if (chunk.isEmpty) {
            continue;
          }
          for (var i = 0; i < chunk.length; i += maxPayload) {
            final end = math.min(i + maxPayload, chunk.length);
            final piece = chunk.sublist(i, end);
            yield filepb.UploadFileRequest(
              chunk: filepb.FileChunk(
                partNumber: partNumber++,
                data: piece,
              ),
            );
            sent += piece.length;
            onProgress?.call(sent, totalBytes);
          }
        }
      }

      final resp = await _authGuard.execute(() => _fileClient.uploadFile(requestStream()));
      return resp.fileId.toInt();
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в uploadFile', e);
      throwGrpcError(e, 'Ошибка загрузки файла');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в uploadFile', e);
      throw ApiFailure('Ошибка загрузки файла');
    }
  }

  @override
  Future<List<Message>> getHistory({
    int? peerUserId,
    int? peerGroupId,
    required int messageId,
    required int limit,
  }) async {
    Logs().d('ChatRemoteDataSource: getHistory peerUserId=$peerUserId peerGroupId=$peerGroupId');
    try {
      final peer = peerGroupId != null && peerGroupId > 0
        ? commonpb.Peer(groupId: Int64(peerGroupId))
        : commonpb.Peer(userId: Int64(peerUserId ?? 0));
      final req = chatpb.GetHistoryRequest(
        peer: peer,
        messageId: Int64(messageId),
        limit: Int64(limit),
      );
      final resp = await _authGuard.execute(() => _client.getHistory(req));

      return MessageMapper.listFromProto(resp.messages);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в getHistory', e);
      throwGrpcError(e, 'Ошибка получения сообщений');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в getHistory', e);
      throw ApiFailure('Ошибка получения сообщений');
    }
  }

  @override
  Future<void> deleteMessages(
    List<int> messageIds, {
    bool forEveryone = true,
  }) async {
    if (messageIds.isEmpty) return;
    Logs().d('ChatRemoteDataSource: deleteMessages count=${messageIds.length} forEveryone=$forEveryone');
    try {
      final req = chatpb.DeleteMessagesRequest(
        messageIds: messageIds.map((id) => Int64(id)).toList(),
        revoke: forEveryone,
      );
      await _authGuard.execute(() => _client.deleteMessages(req));
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в deleteMessages', e);
      throwGrpcError(e, 'Ошибка удаления сообщений');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в deleteMessages', e);
      throw ApiFailure('Ошибка удаления сообщений');
    }
  }

  @override
  Future<void> clearHistory({int? peerUserId, int? peerGroupId}) async {
    Logs().d('ChatRemoteDataSource: clearHistory peerUserId=$peerUserId peerGroupId=$peerGroupId');
    try {
      final peer = peerGroupId != null && peerGroupId > 0
        ? commonpb.Peer(groupId: Int64(peerGroupId))
        : commonpb.Peer(userId: Int64(peerUserId ?? 0));
      final req = chatpb.ClearHistoryRequest(peer: peer);
      await _authGuard.execute(() => _client.clearHistory(req));
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в clearHistory', e);
      throwGrpcError(e, 'Ошибка очистки истории');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в clearHistory', e);
      throw ApiFailure('Ошибка очистки истории');
    }
  }

  @override
  Future<void> deleteChat({int? peerUserId, int? peerGroupId}) async {
    Logs().d('ChatRemoteDataSource: deleteChat peerUserId=$peerUserId peerGroupId=$peerGroupId');
    try {
      final peer = peerGroupId != null && peerGroupId > 0
        ? commonpb.Peer(groupId: Int64(peerGroupId))
        : commonpb.Peer(userId: Int64(peerUserId ?? 0));
      final req = chatpb.DeleteChatRequest(peer: peer);
      await _authGuard.execute(() => _client.deleteChat(req));
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в deleteChat', e);
      throwGrpcError(e, 'Ошибка удаления чата');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в deleteChat', e);
      throw ApiFailure('Ошибка удаления чата');
    }
  }

  @override
  Future<void> sendTyping({int? peerUserId, int? peerGroupId}) async {
    try {
      final commonpb.Peer peer;
      if (peerGroupId != null && peerGroupId > 0) {
        peer = commonpb.Peer(groupId: Int64(peerGroupId));
      } else {
        peer = commonpb.Peer(userId: Int64(peerUserId ?? 0));
      }
      final req = chatpb.SendTypingRequest(peer: peer);
      await _authGuard.execute(() => _client.sendTyping(req));
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка sendTyping', e);
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка sendTyping', e);
    }
  }

  @override
  Future<int> uploadGroupPhoto(int groupId, int fileId) async {
    try {
      final req = chatpb.UploadGroupPhotoRequest(
        groupId: Int64(groupId),
        fileId: Int64(fileId),
      );
      final resp = await _authGuard.execute(() => _client.uploadGroupPhoto(req));
      return resp.avatarFileId.toInt();
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка uploadGroupPhoto', e);
      throwGrpcError(e, 'Ошибка загрузки фото группы');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка uploadGroupPhoto', e);
      throw ApiFailure('Ошибка загрузки фото группы');
    }
  }

  @override
  Future<void> setChatNotifications(Chat chat, bool notificationsMuted) async {
    try {
      final peer = chat.isGroup
          ? commonpb.Peer(groupId: Int64(chat.peerGroupId))
          : commonpb.Peer(userId: Int64(chat.peerUserId));
      final req = chatpb.SetChatNotificationsRequest(
        peer: peer,
        notificationsMuted: notificationsMuted,
      );
      await _authGuard.execute(() => _client.setChatNotifications(req));
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в setChatNotifications', e);
      throwGrpcError(e, 'Ошибка настройки уведомлений');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в setChatNotifications', e);
      throw ApiFailure('Ошибка настройки уведомлений');
    }
  }

  @override
  Future<void> setChatTop({required int listId, required bool pin}) async {
    Logs().d('ChatRemoteDataSource: setChatTop listId=$listId pin=$pin');
    try {
      final req = chatpb.SetChatTopRequest()
        ..listId = Int64(listId)
        ..type = pin ? 1 : 2;
      await _authGuard.execute(() => _client.setChatTop(req));
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в setChatTop', e);
      throwGrpcError(e, 'Ошибка закрепления чата');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в setChatTop', e);
      throw ApiFailure('Ошибка закрепления чата');
    }
  }

  @override
  Future<void> leaveGroup(int groupId) async {
    Logs().d('ChatRemoteDataSource: leaveGroup groupId=$groupId');
    try {
      final req = chatpb.LeaveGroupRequest(groupId: Int64(groupId));
      await _authGuard.execute(() => _client.leaveGroup(req));
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в leaveGroup', e);
      throwGrpcError(e, 'Не удалось выйти из группы');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в leaveGroup', e);
      throw ApiFailure('Не удалось выйти из группы');
    }
  }

  @override
  Future<({List<OvertGroupListing> items, bool hasMore})> searchPublicGroups({
    required String nameQuery,
    required int page,
  }) async {
    Logs().d(
      'ChatRemoteDataSource: searchPublicGroups page=$page name="$nameQuery"',
    );
    try {
      final req = chatpb.SearchPublicGroupsRequest(
        nameQuery: nameQuery,
        page: page,
      );
      final resp = await _authGuard.execute(() => _client.searchPublicGroups(req));
      final items = resp.items
          .map(
            (e) => OvertGroupListing(
              id: e.id.toInt(),
              type: e.type,
              name: e.name,
              avatarUrl: e.avatar,
              description: e.description,
              memberCount: e.memberCount,
              maxNum: e.maxNum,
              createdAtSec: e.createdAt.toInt(),
              isMember: e.isMember,
            ),
          )
          .toList();
      return (items: items, hasMore: resp.hasMore);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: gRPC searchPublicGroups', e);
      throwGrpcError(e, 'Ошибка поиска групп');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: searchPublicGroups', e);
      throw ApiFailure('Ошибка поиска групп');
    }
  }

  @override
  Future<void> requestToJoinGroup(int groupId) async {
    Logs().d('ChatRemoteDataSource: requestToJoinGroup groupId=$groupId');
    try {
      final req = chatpb.RequestToJoinGroupRequest(groupId: Int64(groupId));
      await _authGuard.execute(() => _client.requestToJoinGroup(req));
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: gRPC requestToJoinGroup', e);
      throwGrpcError(e, 'Не удалось отправить заявку');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: requestToJoinGroup', e);
      throw ApiFailure('Не удалось отправить заявку');
    }
  }

  @override
  Future<void> clearUnread({int? peerUserId, int? peerGroupId}) async {
    try {
      final peer = peerGroupId != null && peerGroupId > 0
          ? commonpb.Peer(groupId: Int64(peerGroupId))
          : commonpb.Peer(userId: Int64(peerUserId ?? 0));
      final req = chatpb.ClearUnreadRequest(peer: peer);
      await _authGuard.execute(() => _client.clearUnread(req));
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в clearUnread', e);
      throwGrpcError(e, 'Ошибка сброса непрочитанных');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в clearUnread', e);
      throw ApiFailure('Ошибка сброса непрочитанных');
    }
  }

  @override
  Future<void> reportInlineCallback({
    int? peerUserId,
    int? peerGroupId,
    required int messageId,
    required String callbackData,
  }) async {
    try {
      final peer = peerGroupId != null && peerGroupId > 0
        ? commonpb.Peer(groupId: Int64(peerGroupId))
        : commonpb.Peer(userId: Int64(peerUserId ?? 0));
      final req = chatpb.ReportInlineCallbackRequest(
        peer: peer,
        messageId: Int64(messageId),
        callbackData: callbackData,
      );
      await _authGuard.execute(() => _client.reportInlineCallback(req));
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в reportInlineCallback', e);
      throwGrpcError(e, 'Ошибка отправки callback');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в reportInlineCallback', e);
      throw ApiFailure('Ошибка отправки callback');
    }
  }

  @override
  Future<Message> createPoll({
    required int peerGroupId,
    required String question,
    required List<String> options,
    required bool anonymous,
  }) async {
    try {
      final req = chatpb.CreatePollRequest(
        peer: commonpb.Peer(groupId: Int64(peerGroupId)),
        question: question,
        options: options,
        anonymous: anonymous,
      );
      final resp = await _authGuard.execute(() => _client.createPoll(req));
      return MessageMapper.fromProto(resp.message);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в createPoll', e);
      throwGrpcError(e, 'Ошибка создания опроса');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в createPoll', e);
      throw ApiFailure('Ошибка создания опроса');
    }
  }

  @override
  Future<void> votePoll({
    required int peerGroupId,
    required int messageId,
    required int optionId,
  }) async {
    try {
      final req = chatpb.VotePollRequest(
        peer: commonpb.Peer(groupId: Int64(peerGroupId)),
        messageId: Int64(messageId),
        optionId: Int64(optionId),
      );
      await _authGuard.execute(() => _client.votePoll(req));
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в votePoll', e);
      throwGrpcError(e, 'Ошибка голосования');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в votePoll', e);
      throw ApiFailure('Ошибка голосования');
    }
  }
}
