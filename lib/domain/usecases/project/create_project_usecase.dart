import 'package:voosu/domain/entities/project.dart';
import 'package:voosu/domain/repositories/project_repository.dart';

class CreateProjectUseCase {
  final ProjectRepository repo;

  CreateProjectUseCase(this.repo);

  Future<Project> call(String name) => repo.createProject(name);
}
