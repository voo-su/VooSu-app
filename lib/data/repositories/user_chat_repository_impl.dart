import 'package:voosu/core/failures.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/data_sources/remote/chat_remote_datasource.dart';
import 'package:voosu/data/db/app_database.dart';
import 'package:voosu/domain/entities/chat.dart';
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
  Future<List<Chat>> getChats() async {
    try {
      return await _remote.getChats();
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в getChats', e);
      throw ApiFailure('Ошибка получения чатов');
    }
  }

  @override
  Future<List<Message>> getHistory({
    required int peerUserId,
    required int messageId,
    required int limit,
  }) async {
    try {
      return await _remote.getHistory(
        peerUserId: peerUserId,
        messageId: messageId,
        limit: limit,
      );
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
  Future<void> clearHistory({required int peerUserId}) async {
    try {
      await _remote.clearHistory(peerUserId: peerUserId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в clearHistory', e);
      throw ApiFailure('Ошибка очистки истории');
    }
  }

  @override
  Future<void> deleteChat({required int peerUserId}) async {
    try {
      await _remote.deleteChat(peerUserId: peerUserId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ChatRepository: неожиданная ошибка в deleteChat', e);
      throw ApiFailure('Ошибка удаления чата');
    }
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
