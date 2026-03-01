import 'package:voosu/domain/repositories/project_repository.dart';

class AddUserToProjectUseCase {
  final ProjectRepository repo;

  AddUserToProjectUseCase(this.repo);

  Future<void> call(int projectId, List<int> userIds) => repo.addUserToProject(projectId, userIds);
}
