import 'package:voosu/domain/repositories/chat_repository.dart';

class CollectStickerFromMessageUseCase {
  final ChatRepository _repo;

  CollectStickerFromMessageUseCase(this._repo);

  Future<void> call(int messageId) => _repo.collectStickerFromMessage(messageId);
}
