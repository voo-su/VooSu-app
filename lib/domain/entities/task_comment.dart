import 'package:equatable/equatable.dart';
import 'package:voosu/domain/entities/task_attachment.dart';

class TaskComment extends Equatable {
  final int id;
  final int taskId;
  final int userId;
  final String body;
  final int createdAt;
  final List<TaskAttachment> attachments;

  const TaskComment({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.body,
    required this.createdAt,
    this.attachments = const [],
  });

  @override
  List<Object?> get props => [id, taskId, userId, body, createdAt, attachments];
}
