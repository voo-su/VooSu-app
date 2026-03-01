import 'package:voosu/domain/repositories/project_repository.dart';

class RemoveUserFromProjectUseCase {
  final ProjectRepository repo;

  RemoveUserFromProjectUseCase(this.repo);

  Future<void> call(int projectId, int userId) => repo.removeUserFromProject(projectId, userId);
}
