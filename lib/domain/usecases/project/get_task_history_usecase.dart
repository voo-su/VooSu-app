import 'package:voosu/domain/entities/project_activity.dart';
import 'package:voosu/domain/repositories/project_repository.dart';

class GetTaskHistoryUseCase {
  final ProjectRepository repo;

  GetTaskHistoryUseCase(this.repo);

  Future<List<ProjectActivity>> call(int taskId) => repo.getTaskHistory(taskId);
}
