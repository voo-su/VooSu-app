import 'package:voosu/domain/entities/project.dart';
import 'package:voosu/domain/repositories/project_repository.dart';

class GetProjectsUseCase {
  final ProjectRepository repo;

  GetProjectsUseCase(this.repo);

  Future<List<Project>> call() => repo.getProjects();
}
