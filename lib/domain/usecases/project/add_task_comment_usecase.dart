import 'package:voosu/domain/repositories/project_repository.dart';

class AddTaskCommentUseCase {
  final ProjectRepository repo;

  AddTaskCommentUseCase(this.repo);

  Future<void> call(
    int taskId,
    String body, {
    List<int> attachmentFileIds = const [],
  }) => repo.addTaskComment(taskId, body, attachmentFileIds: attachmentFileIds);
}
