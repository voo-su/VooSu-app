import 'package:voosu/domain/repositories/chat_repository.dart';

class RequestGroupJoinUseCase {
  final ChatRepository _repo;

  RequestGroupJoinUseCase(this._repo);

  Future<void> call(int groupId) => _repo.requestToJoinGroup(groupId);
}
