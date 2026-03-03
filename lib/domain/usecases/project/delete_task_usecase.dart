import 'package:voosu/domain/repositories/project_repository.dart';

class DeleteTaskUseCase {
  final ProjectRepository repo;

  DeleteTaskUseCase(this.repo);

  Future<void> call(int taskId) => repo.deleteTask(taskId);
}
