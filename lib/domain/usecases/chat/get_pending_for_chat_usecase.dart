import 'package:voosu/domain/entities/pending_queue_item.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class GetPendingForChatUseCase {
  final ChatRepository repo;

  GetPendingForChatUseCase(this.repo);

  Future<List<PendingQueueItem>> call(int chatId) async {
    final list = await repo.getPendingForChat(chatId);
    return list.map((m) => PendingQueueItem(
      localId: m['localId'] as String,
      content: m['content'] as String? ?? '',
      attachmentsJson: m['attachmentsJson'] as String?,
      replyToId: m['replyToId'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        ((m['createdAt'] as int?) ?? 0) * 1000,
      ),
    )).toList();
  }
}
