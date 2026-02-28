import 'package:voosu/domain/entities/project.dart';
import 'package:voosu/domain/repositories/project_repository.dart';

class GetProjectUseCase {
  final ProjectRepository repo;

  GetProjectUseCase(this.repo);

  Future<Project> call(int id) => repo.getProject(id);
}
