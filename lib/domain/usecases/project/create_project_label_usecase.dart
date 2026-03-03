import 'package:voosu/domain/entities/project_label.dart';
import 'package:voosu/domain/repositories/project_repository.dart';

class CreateProjectLabelUseCase {
  final ProjectRepository repo;

  CreateProjectLabelUseCase(this.repo);

  Future<ProjectLabel> call(int projectId, String name, String color) => repo.createProjectLabel(projectId, name, color);
}
