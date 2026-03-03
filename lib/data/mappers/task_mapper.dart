import 'package:voosu/domain/entities/project_label.dart';
import 'package:voosu/domain/entities/task.dart';
import 'package:voosu/domain/entities/task_attachment.dart';
import 'package:voosu/generated/grpc_pb/project.pb.dart' as projectpb;

class TaskMapper {
  static List<TaskAttachment> _attachmentsFromProto(
    Iterable<projectpb.TaskAttachment> list,
  ) {
    return list.map((a) => TaskAttachment(
      fileId: a.fileId.toInt(),
      filename: a.filename,
      mimeType: a.mimeType,
      size: a.size.toInt(),
    )).toList();
  }

  static List<ProjectLabel> _labelsFromProto(
    Iterable<projectpb.ProjectLabelItem> list,
  ) {
    return list.map((l) => ProjectLabel(
      id: l.id.toInt(),
      name: l.name,
      color: l.color.isNotEmpty ? l.color : '#9E9E9E',
    )).toList();
  }

  static Task fromProto(projectpb.Task proto, {int projectId = 0}) {
    return Task(
      id: proto.id.toInt(),
      projectId: projectId,
      name: proto.name,
      description: proto.description,
      createdAt: proto.createdAt.toInt(),
      assigner: proto.assigner.toInt(),
      executor: proto.executor.toInt(),
      columnId: proto.columnId > 0 ? proto.columnId.toInt() : 0,
      attachments: _attachmentsFromProto(proto.attachments),
      labels: _labelsFromProto(proto.labels),
    );
  }

  static List<Task> listFromProto(
    Iterable<projectpb.Task> list, {
    int projectId = 0,
  }) {
    return list.map((task) => fromProto(task, projectId: projectId)).toList();
  }

  static Task fromGetTaskResponse(
    projectpb.GetTaskResponse resp, {
    int projectId = 0,
  }) {
    return Task(
      id: resp.id.toInt(),
      projectId: projectId,
      name: resp.name,
      description: resp.description,
      createdAt: resp.createdAt.toInt(),
      assigner: resp.assigner.toInt(),
      executor: resp.executor.toInt(),
      columnId: resp.columnId > 0 ? resp.columnId.toInt() : 0,
      attachments: _attachmentsFromProto(resp.attachments),
      labels: _labelsFromProto(resp.labels),
    );
  }
}
