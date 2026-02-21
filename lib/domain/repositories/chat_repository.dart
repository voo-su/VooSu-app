import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/message.dart';

abstract class ChatRepository {
  Future<Chat> createChat(int userId);

  Future<List<Chat>> getChats();

  Future<List<Message>> getHistory({
    required int peerUserId,
    required int messageId,
    required int limit,
  });

  Future<void> deleteMessages(List<int> messageIds, {bool forEveryone = true});

  Future<void> clearHistory({required int peerUserId});

  Future<void> deleteChat({required int peerUserId});

  Future<List<Map<String, dynamic>>> getPendingForChat(int chatId);

  Future<void> removePendingMessage(String localId);
}
