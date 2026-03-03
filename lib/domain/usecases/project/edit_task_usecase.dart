import 'package:voosu/domain/entities/task.dart';
import 'package:voosu/domain/repositories/project_repository.dart';

class EditTaskUseCase {
  final ProjectRepository repo;

  EditTaskUseCase(this.repo);

  Future<Task> call(
    int taskId,
    String name,
    String description,
    int assigner,
    int executor,
    {List<int>? labelIds}
  ) => repo.editTask(
    taskId,
    name,
    description,
    assigner,
    executor,
    labelIds: labelIds,
  );
}
