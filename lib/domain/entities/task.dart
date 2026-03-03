import 'package:equatable/equatable.dart';
import 'package:voosu/domain/entities/project_label.dart';
import 'package:voosu/domain/entities/task_attachment.dart';

class Task extends Equatable {
  final int id;
  final int projectId;
  final String name;
  final String description;
  final int createdAt;
  final int assigner;
  final int executor;
  final int columnId;
  final List<TaskAttachment> attachments;
  final List<ProjectLabel> labels;

  const Task({
    required this.id,
    required this.projectId,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.assigner,
    required this.executor,
    this.columnId = 0,
    this.attachments = const [],
    this.labels = const [],
  });

  Task copyWith({
    int? id,
    int? projectId,
    String? name,
    String? description,
    int? createdAt,
    int? assigner,
    int? executor,
    int? columnId,
    List<TaskAttachment>? attachments,
    List<ProjectLabel>? labels,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      assigner: assigner ?? this.assigner,
      executor: executor ?? this.executor,
      columnId: columnId ?? this.columnId,
      attachments: attachments ?? this.attachments,
      labels: labels ?? this.labels,
    );
  }

  @override
  List<Object?> get props => [
    id,
    projectId,
    name,
    description,
    createdAt,
    assigner,
    executor,
    columnId,
    attachments,
    labels,
  ];
}
