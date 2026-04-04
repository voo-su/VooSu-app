import 'package:voosu/domain/entities/user_sticker.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class AddStickerFromUploadedFileUseCase {
  final ChatRepository _repo;

  AddStickerFromUploadedFileUseCase(this._repo);

  Future<UserSticker> call(String fileId) => _repo.addStickerFromUploadedFile(fileId);
}
