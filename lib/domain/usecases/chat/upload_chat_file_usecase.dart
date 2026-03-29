import 'package:voosu/core/failures.dart';
import 'package:voosu/data/services/upload_queue_service.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class UploadChatFileUseCase {
  final ChatRepository _repo;
  final UploadQueueService? _uploadQueue;

  UploadChatFileUseCase(this._repo, [this._uploadQueue]);

  Future<int> call({
    required String filename,
    String mimeType = '',
    required Stream<List<int>> chunkStream,
    int? totalBytes,
    void Function(int sentBytes, int? totalBytes)? onProgress,
  }) async {
    final queue = _uploadQueue;
    String? taskId;
    if (queue != null) {
      taskId = queue.begin(filename: filename, totalBytes: totalBytes);
    }
    try {
      final fileId = await _repo.uploadFile(
        filename: filename,
        mimeType: mimeType,
        chunkStream: chunkStream,
        totalBytes: totalBytes,
        onProgress: (sent, total) {
          final tid = taskId;
          final q = queue;
          if (tid != null && q != null) {
            q.reportProgress(tid, sent, total ?? totalBytes);
          }
          onProgress?.call(sent, total);
        },
      );
      final tid = taskId;
      final q = queue;
      if (tid != null && q != null) {
        q.complete(tid);
      }
      return fileId;
    } catch (e) {
      final tid = taskId;
      final q = queue;
      if (tid != null && q != null) {
        final msg = e is Failure ? e.message : e.toString();
        q.fail(tid, msg);
      }
      rethrow;
    }
  }
}
