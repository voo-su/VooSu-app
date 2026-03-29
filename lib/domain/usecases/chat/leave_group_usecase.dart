import 'package:voosu/domain/repositories/chat_repository.dart';

class LeaveGroupUseCase {
  final ChatRepository _repo;

  LeaveGroupUseCase(this._repo);

  Future<void> call(int groupId) => _repo.leaveGroup(groupId);
}
