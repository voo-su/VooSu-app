import 'package:voosu/domain/repositories/chat_repository.dart';

class SetChatPinUseCase {
  final ChatRepository _repo;

  SetChatPinUseCase(this._repo);

  Future<void> call({required int listId, required bool pin}) =>
      _repo.setChatTop(listId: listId, pin: pin);
}
