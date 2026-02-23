import 'package:voosu/domain/repositories/chat_repository.dart';

class UploadChatFileUseCase {
  final ChatRepository _repo;

  UploadChatFileUseCase(this._repo);

  Future<int> call({
    required String filename,
    String mimeType = '',
    required Stream<List<int>> chunkStream,
    int? totalBytes,
    void Function(int sentBytes, int? totalBytes)? onProgress,
  }) => _repo.uploadFile(
    filename: filename,
    mimeType: mimeType,
    chunkStream: chunkStream,
    totalBytes: totalBytes,
    onProgress: onProgress,
  );
}
