import 'package:voosu/domain/repositories/project_repository.dart';

class UpdateProjectUseCase {
  final ProjectRepository repo;

  UpdateProjectUseCase(this.repo);

  Future<void> call(int projectId, String name) => repo.updateProject(projectId, name);
}
