import 'package:voosu/data/db/app_database.dart';
import 'package:voosu/domain/entities/pending_queue_item.dart';

class GetPendingForChatUseCase {
  final AppDatabase _db;

  GetPendingForChatUseCase(this._db);

  Future<List<PendingQueueItem>> call(int chatId) async {
    final rows = await _db.getPendingForChat(chatId);
    return rows
        .map(
          (r) => PendingQueueItem(
            localId: r.localId,
            content: r.content,
            attachmentsJson: r.attachmentsJson,
            replyToId: r.replyToId,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              (r.createdAt) * 1000,
            ),
          ),
        )
        .toList();
  }
}
