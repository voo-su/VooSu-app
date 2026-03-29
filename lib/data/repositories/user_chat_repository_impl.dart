import 'package:voosu/core/failures.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/data_sources/remote/chat_remote_datasource.dart';
import 'package:voosu/data/db/app_database.dart';
import 'package:voosu/domain/entities/attachment_upload.dart';
import 'package:voosu/domain/entities/group_message_mention.dart';
import 'package:voosu/domain/entities/mixed_send_item.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/group_info.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/entities/overt_group_listing.dart';
import 'package:voosu/domain/entities/user_sticker.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final IChatRemoteDataSource _remote;
  final AppDatabase? _db;

  ChatRepositoryImpl(this._remote, [this._db]);

  @override
  Future<Chat> createChat(int userId) async {
    try {
      return await _remote.createChat(userId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в createChat', e);
      throw ApiFailure('Ошибка открытия чата');
    }
  }

  @override
  Future<Chat> createGroupChat({
    required String title,
    required List<int> userIds,
  }) async {
    try {
      return await _remote.createGroupChat(title: title, userIds: userIds);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в createGroupChat', e);
      throw ApiFailure('Ошибка создания группового чата');
    }
  }

  @override
  Future<List<Chat>> getChats() async {
    try {
      final chats = await _remote.getChats();
      await _db?.cacheChats(chats);

      return chats;
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в getChats', e);
      throw ApiFailure('Ошибка получения чатов');
    }
  }

  @override
  Future<List<Chat>> getCachedChats() async {
    if (_db == null) {
      return [];
    }

    return _db.getCachedChats();
  }

  @override
  Future<List<Message>> getCachedMessagesForChat(
    int chatId,
    int limit, {
    int? beforeMessageId,
  }) async {
    if (_db == null) {
      return [];
    }

    return _db.getCachedMessagesForChat(
      chatId,
      limit,
      beforeMessageId: beforeMessageId,
    );
  }

  @override
  Future<bool> hasOlderCachedMessages(
    int chatId,
    int oldestMessageId,
  ) async {
    if (_db == null) {
      return false;
    }

    return _db.hasOlderCachedMessages(chatId, oldestMessageId);
  }

  @override
  Future<GroupInfo> getGroupInfo(int groupId) async {
    try {
      return await _remote.getGroupInfo(groupId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в getGroupInfo', e);
      throw ApiFailure('Ошибка загрузки информации о группе');
    }
  }

  @override
  Future<void> addGroupMembers(int groupId, List<int> userIds) async {
    try {
      await _remote.addGroupMembers(groupId, userIds);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в addGroupMembers', e);
      throw ApiFailure('Ошибка добавления участников');
    }
  }

  @override
  Future<void> removeGroupMembers(int groupId, List<int> userIds) async {
    try {
      await _remote.removeGroupMembers(groupId, userIds);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в removeGroupMembers', e);
      throw ApiFailure('Ошибка удаления участников');
    }
  }

  @override
  Future<void> setGroupMemberRole(int groupId, int userId, int role) async {
    try {
      await _remote.setGroupMemberRole(groupId, userId, role);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в setGroupMemberRole', e);
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
    try {
      return await _remote.sendMessage(
        peerUserId: peerUserId,
        peerGroupId: peerGroupId,
        content: content,
        replyToMessageId: replyToMessageId,
        forwarded: forwarded,
        forwardedFromMessageId: forwardedFromMessageId,
        attachments: attachments,
        mention: mention,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в sendMessage', e);
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
      return await _remote.sendMixedMessage(
        peerUserId: peerUserId,
        peerGroupId: peerGroupId,
        items: items,
        replyToMessageId: replyToMessageId,
        mention: mention,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в sendMixedMessage', e);
      throw ApiFailure('Ошибка отправки сообщения');
    }
  }

  @override
  Future<List<UserSticker>> listMyStickers() async {
    try {
      return await _remote.listMyStickers();
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в listMyStickers', e);
      throw ApiFailure('Ошибка загрузки стикеров');
    }
  }

  @override
  Future<UserSticker> addStickerFromUploadedFile(int fileId) async {
    try {
      return await _remote.addStickerFromUploadedFile(fileId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в addStickerFromUploadedFile', e);
      throw ApiFailure('Не удалось добавить стикер');
    }
  }

  @override
  Future<void> deleteMyStickers(List<int> stickerIds) async {
    try {
      await _remote.deleteMyStickers(stickerIds);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в deleteMyStickers', e);
      throw ApiFailure('Не удалось удалить стикер');
    }
  }

  @override
  Future<void> collectStickerFromMessage(int messageId) async {
    try {
      await _remote.collectStickerFromMessage(messageId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в collectStickerFromMessage', e);
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
      return await _remote.sendSticker(
        peerUserId: peerUserId,
        peerGroupId: peerGroupId,
        stickerId: stickerId,
        replyToMessageId: replyToMessageId,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в sendSticker', e);
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
      return await _remote.sendCodeMessage(
        peerUserId: peerUserId,
        peerGroupId: peerGroupId,
        lang: lang,
        code: code,
        replyToMessageId: replyToMessageId,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в sendCodeMessage', e);
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
      return await _remote.sendLocationMessage(
        peerUserId: peerUserId,
        peerGroupId: peerGroupId,
        latitude: latitude,
        longitude: longitude,
        description: description,
        replyToMessageId: replyToMessageId,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в sendLocationMessage', e);
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
    try {
      return await _remote.uploadFile(
        filename: filename,
        mimeType: mimeType,
        chunkStream: chunkStream,
        totalBytes: totalBytes,
        onProgress: onProgress,
      );
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      Logs().e('ChatRepository: ошибка uploadFile', e);
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
    try {
      final messages = await _remote.getHistory(
        peerUserId: peerUserId,
        peerGroupId: peerGroupId,
        messageId: messageId,
        limit: limit,
      );
      for (final m in messages) {
        await _db?.cacheMessage(m);
      }

      return messages;
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в getHistory', e);
      throw ApiFailure('Ошибка получения сообщений');
    }
  }

  @override
  Future<void> deleteMessages(
    List<int> messageIds, {
    bool forEveryone = true,
  }) async {
    if (messageIds.isEmpty) return;
    try {
      await _remote.deleteMessages(messageIds, forEveryone: forEveryone);
      await _db?.deleteCachedMessages(messageIds);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в deleteMessages', e);
      throw ApiFailure('Ошибка удаления сообщений');
    }
  }

  @override
  Future<void> deleteCachedMessages(List<int> messageIds) async {
    if (messageIds.isEmpty) {
      return;
    }

    await _db?.deleteCachedMessages(messageIds);
  }

  @override
  Future<void> clearCachedMessagesForChat(int chatId) async {
    await _db?.clearCachedMessagesForChat(chatId);
  }

  @override
  Future<void> clearHistory({int? peerUserId, int? peerGroupId}) async {
    try {
      await _remote.clearHistory(
        peerUserId: peerUserId,
        peerGroupId: peerGroupId,
      );
      final chatId = peerGroupId != null && peerGroupId > 0
        ? -peerGroupId
        : peerUserId!;
      await _db?.clearCachedMessagesForChat(chatId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в clearHistory', e);
      throw ApiFailure('Ошибка очистки истории');
    }
  }

  @override
  Future<void> deleteChat({int? peerUserId, int? peerGroupId}) async {
    try {
      await _remote.deleteChat(
        peerUserId: peerUserId,
        peerGroupId: peerGroupId,
      );
      final chatId = peerGroupId != null && peerGroupId > 0
        ? -peerGroupId
        : peerUserId!;
      await _db?.deleteCachedChat(chatId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в deleteChat', e);
      throw ApiFailure('Ошибка удаления чата');
    }
  }

  @override
  Future<void> sendTyping({int? peerUserId, int? peerGroupId}) async {
    await _remote.sendTyping(peerUserId: peerUserId, peerGroupId: peerGroupId);
  }

  @override
  Future<int> uploadGroupPhoto(int groupId, int fileId) async {
    try {
      return await _remote.uploadGroupPhoto(groupId, fileId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: ошибка uploadGroupPhoto', e);
      throw ApiFailure('Ошибка загрузки фото группы');
    }
  }

  @override
  Future<void> setChatNotifications(Chat chat, bool notificationsMuted) async {
    try {
      await _remote.setChatNotifications(chat, notificationsMuted);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: ошибка в setChatNotifications', e);
      throw ApiFailure('Ошибка настройки уведомлений');
    }
  }

  @override
  Future<void> setChatTop({required int listId, required bool pin}) async {
    try {
      await _remote.setChatTop(listId: listId, pin: pin);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: ошибка в setChatTop', e);
      throw ApiFailure('Ошибка закрепления чата');
    }
  }

  @override
  Future<void> leaveGroup(int groupId) async {
    try {
      await _remote.leaveGroup(groupId);
      await _db?.deleteCachedChat(-groupId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: ошибка в leaveGroup', e);
      throw ApiFailure('Не удалось выйти из группы');
    }
  }

  @override
  Future<({List<OvertGroupListing> items, bool hasMore})> searchPublicGroups({
    required String nameQuery,
    required int page,
  }) async {
    try {
      return await _remote.searchPublicGroups(nameQuery: nameQuery, page: page);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: searchPublicGroups', e);
      throw ApiFailure('Ошибка поиска групп');
    }
  }

  @override
  Future<void> requestToJoinGroup(int groupId) async {
    try {
      await _remote.requestToJoinGroup(groupId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: requestToJoinGroup', e);
      throw ApiFailure('Не удалось отправить заявку');
    }
  }

  @override
  Future<void> clearUnread({int? peerUserId, int? peerGroupId}) async {
    try {
      await _remote.clearUnread(
        peerUserId: peerUserId,
        peerGroupId: peerGroupId,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: ошибка в clearUnread', e);
      throw ApiFailure('Ошибка сброса непрочитанных');
    }
  }

  @override
  Future<void> reportInlineCallback({
    required Chat chat,
    required int messageId,
    required String callbackData,
  }) async {
    try {
      await _remote.reportInlineCallback(
        peerUserId: chat.isGroup ? null : chat.peerUserId,
        peerGroupId: chat.isGroup ? chat.peerGroupId : null,
        messageId: messageId,
        callbackData: callbackData,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: ошибка в reportInlineCallback', e);
      throw ApiFailure('Ошибка отправки callback');
    }
  }

  @override
  Future<Message> createPoll({
    required int groupId,
    required String question,
    required List<String> options,
    required bool anonymous,
  }) async {
    try {
      return await _remote.createPoll(
        peerGroupId: groupId,
        question: question,
        options: options,
        anonymous: anonymous,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: ошибка в createPoll', e);
      throw ApiFailure('Ошибка создания опроса');
    }
  }

  @override
  Future<void> votePoll({
    required int groupId,
    required int messageId,
    required int optionId,
  }) async {
    try {
      await _remote.votePoll(
        peerGroupId: groupId,
        messageId: messageId,
        optionId: optionId,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: ошибка в votePoll', e);
      throw ApiFailure('Ошибка голосования');
    }
  }

  @override
  Future<void> savePendingMessage({
    required String localId,
    required int peerUserId,
    required int peerGroupId,
    required String content,
    String? attachmentsJson,
    int replyToId = 0,
  }) async {
    await _db?.insertPendingMessage(
      localId: localId,
      peerUserId: peerUserId,
      peerGroupId: peerGroupId,
      content: content,
      attachmentsJson: attachmentsJson,
      replyToId: replyToId,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingOutgoingMessages() async {
    if (_db == null) {
      return [];
    }

    final rows = await _db.getPendingOutgoingMessages();
    return rows.map((r) => {
      'localId': r.localId,
      'peerUserId': r.peerUserId,
      'peerGroupId': r.peerGroupId,
      'content': r.content,
      'attachmentsJson': r.attachmentsJson,
      'replyToId': r.replyToId,
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingForChat(int chatId) async {
    if (_db == null) {
      return [];
    }

    final rows = await _db.getPendingForChat(chatId);
    return rows.map((r) => {
      'localId': r.localId,
      'content': r.content,
      'attachmentsJson': r.attachmentsJson,
      'replyToId': r.replyToId,
      'createdAt': r.createdAt,
    }).toList();
  }

  @override
  Future<void> removePendingMessage(String localId) async {
    await _db?.deletePendingMessage(localId);
  }
}
