import 'package:voosu/domain/entities/project_activity.dart';
import 'package:voosu/domain/repositories/project_repository.dart';

class GetProjectHistoryUseCase {
  final ProjectRepository repo;

  GetProjectHistoryUseCase(this.repo);

  Future<List<ProjectActivity>> call(int projectId) => repo.getProjectHistory(projectId);
}
