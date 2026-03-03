import 'package:voosu/domain/entities/task.dart';
import 'package:voosu/domain/repositories/project_repository.dart';

class GetTasksUseCase {
  final ProjectRepository repo;

  GetTasksUseCase(this.repo);

  Future<List<Task>> call(int projectId) => repo.getTasks(projectId);
}
