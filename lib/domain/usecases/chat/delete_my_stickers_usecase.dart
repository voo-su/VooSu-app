import 'package:voosu/domain/repositories/chat_repository.dart';

class DeleteMyStickersUseCase {
  final ChatRepository _repo;

  DeleteMyStickersUseCase(this._repo);

  Future<void> call(List<int> stickerIds) => _repo.deleteMyStickers(stickerIds);
}
