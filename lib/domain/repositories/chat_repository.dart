import 'package:voosu/domain/entities/attachment_upload.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/message.dart';

abstract class ChatRepository {
  Future<Chat> createChat(int userId);

  Future<List<Chat>> getChats();

  Future<Message> sendMessage({
    required int peerUserId,
    required String content,
    int replyToMessageId = 0,
    bool forwarded = false,
    int forwardedFromMessageId = 0,
    List<AttachmentUpload>? attachments,
  });

  Future<int> uploadFile({
    required String filename,
    String mimeType = '',
    required Stream<List<int>> chunkStream,
    int? totalBytes,
    void Function(int sentBytes, int? totalBytes)? onProgress,
  });

  Future<List<Message>> getHistory({
    required int peerUserId,
    required int messageId,
    required int limit,
  });

  Future<void> deleteMessages(List<int> messageIds, {bool forEveryone = true});

  Future<void> clearHistory({required int peerUserId});

  Future<void> deleteChat({required int peerUserId});

  Future<void> savePendingMessage({
    required String localId,
    required int peerUserId,
    required String content,
    String? attachmentsJson,
    int replyToId = 0,
  });

  Future<List<Map<String, dynamic>>> getPendingOutgoingMessages();

  Future<List<Map<String, dynamic>>> getPendingForChat(int chatId);

  Future<void> removePendingMessage(String localId);
}
