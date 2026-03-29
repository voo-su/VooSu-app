import 'package:voosu/domain/entities/user_sticker.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class ListMyStickersUseCase {
  final ChatRepository _repo;

  ListMyStickersUseCase(this._repo);

  Future<List<UserSticker>> call() => _repo.listMyStickers();
}
