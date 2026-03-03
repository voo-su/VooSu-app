import 'package:voosu/domain/entities/task.dart';

class TaskUpdatePayload {
  final int projectId;
  final Task? task;

  const TaskUpdatePayload({
    required this.projectId,
    this.task,
  });
}
