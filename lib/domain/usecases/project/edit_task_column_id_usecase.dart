import 'package:voosu/domain/repositories/project_repository.dart';

class EditTaskColumnIdUseCase {
  final ProjectRepository repo;

  EditTaskColumnIdUseCase(this.repo);

  Future<void> call(int taskId, int columnId) => repo.editTaskColumnId(taskId, columnId);
}
