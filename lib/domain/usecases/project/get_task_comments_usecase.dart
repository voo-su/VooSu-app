import 'package:voosu/domain/entities/task_comment.dart';
import 'package:voosu/domain/repositories/project_repository.dart';

class GetTaskCommentsUseCase {
  final ProjectRepository repo;

  GetTaskCommentsUseCase(this.repo);

  Future<List<TaskComment>> call(int taskId) => repo.getTaskComments(taskId);
}
