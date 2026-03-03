import 'package:voosu/domain/entities/task.dart';
import 'package:voosu/domain/repositories/project_repository.dart';

class GetTaskUseCase {
  final ProjectRepository repo;

  GetTaskUseCase(this.repo);

  Future<Task> call(int taskId) => repo.getTask(taskId);
}
