import 'package:voosu/domain/entities/attachment_upload.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/group_info.dart';
import 'package:voosu/domain/entities/message.dart';

abstract class ChatRepository {
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

  Future<int> uploadGroupPhoto(int groupId, int fileId);

  Future<Message> createPoll({
    required int groupId,
    required String question,
    required List<String> options,
    required bool anonymous,
  });

  Future<void> votePoll({
    required int groupId,
    required int messageId,
    required int optionId,
  });

  Future<void> savePendingMessage({
    required String localId,
    required int peerUserId,
    required int peerGroupId,
    required String content,
    String? attachmentsJson,
    int replyToId = 0,
  });

  Future<List<Map<String, dynamic>>> getPendingOutgoingMessages();

  Future<List<Map<String, dynamic>>> getPendingForChat(int chatId);

  Future<void> removePendingMessage(String localId);
}
