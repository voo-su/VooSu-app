import 'package:voosu/domain/entities/project_label.dart';
import 'package:voosu/domain/repositories/project_repository.dart';

class GetProjectLabelsUseCase {
  final ProjectRepository repo;

  GetProjectLabelsUseCase(this.repo);

  Future<List<ProjectLabel>> call(int projectId) => repo.getProjectLabels(projectId);
}
