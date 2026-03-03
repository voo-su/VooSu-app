import 'package:equatable/equatable.dart';
import 'package:voosu/domain/entities/task.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class TasksLoadRequested extends TaskEvent {
  final int projectId;

  const TasksLoadRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class TaskCreateRequested extends TaskEvent {
  final int projectId;
  final String name;
  final String description;
  final int executor;
  final List<int> attachmentFileIds;
  final List<int> labelIds;

  const TaskCreateRequested({
    required this.projectId,
    required this.name,
    required this.description,
    required this.executor,
    this.attachmentFileIds = const [],
    this.labelIds = const [],
  });

  @override
  List<Object?> get props => [
    projectId,
    name,
    description,
    executor,
    attachmentFileIds,
    labelIds,
  ];
}

class TaskSelected extends TaskEvent {
  final Task task;

  const TaskSelected(this.task);

  @override
  List<Object?> get props => [task];
}

class TaskClearSelection extends TaskEvent {
  const TaskClearSelection();
}

class TaskClearError extends TaskEvent {
  const TaskClearError();
}

class TaskColumnIdEditRequested extends TaskEvent {
  final int taskId;
  final int columnId;

  const TaskColumnIdEditRequested({
    required this.taskId,
    required this.columnId,
  });

  @override
  List<Object?> get props => [taskId, columnId];
}

class TaskEditRequested extends TaskEvent {
  final int taskId;
  final String name;
  final String description;
  final int assigner;
  final int executor;
  final List<int>? labelIds;

  const TaskEditRequested({
    required this.taskId,
    required this.name,
    required this.description,
    required this.assigner,
    required this.executor,
    this.labelIds,
  });

  @override
  List<Object?> get props => [
    taskId,
    name,
    description,
    assigner,
    executor,
    labelIds,
  ];
}

class TaskDeleteRequested extends TaskEvent {
  final int taskId;

  const TaskDeleteRequested(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class TaskUpdatedFromSync extends TaskEvent {
  final int projectId;
  final Task task;

  const TaskUpdatedFromSync({required this.projectId, required this.task});

  @override
  List<Object?> get props => [projectId, task];
}
