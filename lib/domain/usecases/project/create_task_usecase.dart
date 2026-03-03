import 'package:voosu/domain/entities/task.dart';
import 'package:voosu/domain/repositories/project_repository.dart';

class CreateTaskUseCase {
  final ProjectRepository repo;

  CreateTaskUseCase(this.repo);

  Future<Task> call(
    int projectId,
    String name,
    String description,
    int executor, {
    List<int> attachmentFileIds = const [],
    List<int> labelIds = const [],
  }) => repo.createTask(
    projectId,
    name,
    description,
    executor,
    attachmentFileIds: attachmentFileIds,
    labelIds: labelIds,
  );
}
