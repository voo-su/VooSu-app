import 'package:voosu/core/failures.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/data_sources/remote/chat_remote_datasource.dart';
import 'package:voosu/data/db/app_database.dart';
import 'package:voosu/domain/entities/attachment_upload.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/group_info.dart';
import 'package:voosu/domain/entities/message.dart';
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

      return chats;
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в getChats', e);
      throw ApiFailure('Ошибка получения чатов');
    }
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
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в sendMessage', e);
      throw ApiFailure('Ошибка отправки сообщения');
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
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в deleteMessages', e);
      throw ApiFailure('Ошибка удаления сообщений');
    }
  }

  @override
  Future<void> clearHistory({int? peerUserId, int? peerGroupId}) async {
    try {
      await _remote.clearHistory(
        peerUserId: peerUserId,
        peerGroupId: peerGroupId,
      );
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
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в deleteChat', e);
      throw ApiFailure('Ошибка удаления чата');
    }
  }

  @override
  Future<void> sendTyping(int peerUserId) async {
    await _remote.sendTyping(peerUserId);
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
