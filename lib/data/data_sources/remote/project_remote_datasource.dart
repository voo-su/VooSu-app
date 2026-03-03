import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:voosu/core/auth_guard.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/grpc_channel_manager.dart';
import 'package:voosu/core/grpc_error_handler.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/mappers/project_mapper.dart';
import 'package:voosu/data/mappers/task_mapper.dart';
import 'package:voosu/data/mappers/board_column_mapper.dart';
import 'package:voosu/domain/entities/board_column.dart';
import 'package:voosu/domain/entities/project.dart';
import 'package:voosu/domain/entities/project_activity.dart';
import 'package:voosu/domain/entities/project_label.dart';
import 'package:voosu/domain/entities/project_member_item.dart';
import 'package:voosu/domain/entities/task.dart';
import 'package:voosu/domain/entities/task_attachment.dart';
import 'package:voosu/domain/entities/task_comment.dart';
import 'package:voosu/generated/grpc_pb/project.pbgrpc.dart' as projectpb;

abstract class IProjectRemoteDataSource {
  Future<Project> createProject(String name);

  Future<List<Project>> getProjects();

  Future<Project> getProject(int id);

  Future<void> updateProject(int projectId, String name);

  Future<void> addUserToProject(int projectId, List<int> userIds);

  Future<void> removeUserFromProject(int projectId, int userId);

  Future<List<ProjectMemberItem>> getProjectMembers(int projectId);

  Future<Task> createTask(
    int projectId,
    String name,
    String description,
    int executor, {
    List<int> attachmentFileIds = const [],
    List<int> labelIds = const [],
  });

  Future<List<Task>> getTasks(int projectId);

  Future<Task> getTask(int taskId);

  Future<void> editTaskColumnId(int taskId, int columnId);

  Future<Task> editTask(
    int taskId,
    String name,
    String description,
    int assigner,
    int executor, {
    List<int>? labelIds,
  });

  Future<void> deleteTask(int taskId);

  Future<List<BoardColumn>> getProjectColumns(int projectId);

  Future<BoardColumn> createProjectColumn(
    int projectId,
    String title,
    String color, {
    String? statusKey,
  });

  Future<void> editProjectColumn(
    int id, {
    String? title,
    String? color,
    String? statusKey,
    int? position,
  });

  Future<void> deleteProjectColumn(int id);

  Future<List<ProjectLabel>> getProjectLabels(int projectId);

  Future<ProjectLabel> createProjectLabel(
    int projectId,
    String name,
    String color,
  );

  Future<void> updateProjectLabel(
    int id, {
    String? name,
    String? color,
  });

  Future<void> deleteProjectLabel(int id);

  Future<List<TaskComment>> getTaskComments(int taskId);

  Future<void> addTaskComment(
    int taskId,
    String body, {
    List<int> attachmentFileIds = const [],
  });

  Future<List<ProjectActivity>> getProjectHistory(int projectId);

  Future<List<ProjectActivity>> getTaskHistory(int taskId);
}

class ProjectRemoteDataSource implements IProjectRemoteDataSource {
  final GrpcChannelManager _channelManager;
  final AuthGuard _authGuard;

  ProjectRemoteDataSource(this._channelManager, this._authGuard);

  projectpb.ProjectServiceClient get _client => _channelManager.projectClient;

  @override
  Future<Project> createProject(String name) async {
    Logs().d('ProjectRemoteDataSource: createProject name=$name');
    try {
      final req = projectpb.CreateProjectRequest(name: name);
      final resp = await _authGuard.execute(() => _client.createProject(req));

      return Project(id: resp.id.toInt(), name: name);
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в createProject', e);
      throwGrpcError(e, 'Ошибка создания проекта');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в createProject', e);
      throw ApiFailure('Ошибка создания проекта');
    }
  }

  @override
  Future<List<Project>> getProjects() async {
    Logs().d('ProjectRemoteDataSource: getProjects');
    try {
      final req = projectpb.GetProjectsRequest();
      final resp = await _authGuard.execute(() => _client.getProjects(req));

      return ProjectMapper.listFromProto(resp.items);
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в getProjects', e);
      throwGrpcError(e, 'Ошибка получения проектов');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в getProjects', e);
      throw ApiFailure('Ошибка получения проектов');
    }
  }

  @override
  Future<Project> getProject(int id) async {
    Logs().d('ProjectRemoteDataSource: getProject id=$id');
    try {
      final req = projectpb.GetProjectRequest(id: Int64(id));
      final resp = await _authGuard.execute(() => _client.getProject(req));

      return ProjectMapper.fromGetProjectResponse(resp);
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в getProject', e);
      throwGrpcError(e, 'Ошибка получения проекта');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в getProject', e);
      throw ApiFailure('Ошибка получения проекта');
    }
  }

  @override
  Future<void> updateProject(int projectId, String name) async {
    Logs().d('ProjectRemoteDataSource: updateProject projectId=$projectId');
    try {
      final req = projectpb.UpdateProjectRequest(
        projectId: Int64(projectId),
        name: name,
      );
      await _authGuard.execute(() => _client.updateProject(req));
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в updateProject', e);
      throwGrpcError(e, 'Ошибка переименования проекта');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в updateProject', e);
      throw ApiFailure('Ошибка переименования проекта');
    }
  }

  @override
  Future<void> addUserToProject(int projectId, List<int> userIds) async {
    Logs().d('ProjectRemoteDataSource: addUserToProject projectId=$projectId');
    try {
      final req = projectpb.AddUserToProjectRequest(
        projectId: Int64(projectId),
        userIds: userIds.map((id) => Int64(id)).toList(),
      );
      await _authGuard.execute(() => _client.addUserToProject(req));
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в addUserToProject', e);
      throwGrpcError(e, 'Ошибка добавления участников');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в addUserToProject', e);
      throw ApiFailure('Ошибка добавления участников');
    }
  }

  @override
  Future<void> removeUserFromProject(int projectId, int userId) async {
    Logs().d('ProjectRemoteDataSource: removeUserFromProject projectId=$projectId');
    try {
      final req = projectpb.RemoveUserFromProjectRequest(
        projectId: Int64(projectId),
        userId: Int64(userId),
      );
      await _authGuard.execute(() => _client.removeUserFromProject(req));
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в removeUserFromProject', e);
      throwGrpcError(e, 'Ошибка удаления участника');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в removeUserFromProject', e);
      throw ApiFailure('Ошибка удаления участника');
    }
  }

  @override
  Future<List<ProjectMemberItem>> getProjectMembers(int projectId) async {
    Logs().d('ProjectRemoteDataSource: getProjectMembers projectId=$projectId');
    try {
      final req = projectpb.GetProjectMembersRequest(projectId: Int64(projectId));
      final resp = await _authGuard.execute(
        () => _client.getProjectMembers(req),
      );

      return ProjectMapper.memberListFromProto(resp.items);
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в getProjectMembers', e);
      throwGrpcError(e, 'Ошибка получения участников');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в getProjectMembers', e);
      throw ApiFailure('Ошибка получения участников');
    }
  }

  @override
  Future<Task> createTask(
    int projectId,
    String name,
    String description,
    int executor, {
    List<int> attachmentFileIds = const [],
    List<int> labelIds = const [],
  }) async {
    Logs().d(
      'ProjectRemoteDataSource: createTask projectId=$projectId, name=$name, executor=$executor',
    );
    try {
      final attachments = attachmentFileIds.map((fileId) => projectpb.TaskAttachmentUpload(
        fileId: Int64(fileId),
        filename: '',
      ))
      .toList();
      final req = projectpb.CreateTaskRequest(
        projectId: Int64(projectId),
        name: name,
        description: description,
        executor: Int64(executor),
        attachments: attachments,
        labelIds: labelIds.map((id) => Int64(id)).toList(),
      );
      final resp = await _authGuard.execute(() => _client.createTask(req));

      final taskReq = projectpb.GetTaskRequest(taskId: resp.id);
      final taskResp = await _authGuard.execute(() => _client.getTask(taskReq));

      return TaskMapper.fromGetTaskResponse(taskResp, projectId: projectId);
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в createTask', e);
      throwGrpcError(e, 'Ошибка создания задачи');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в createTask', e);
      throw ApiFailure('Ошибка создания задачи');
    }
  }

  @override
  Future<List<Task>> getTasks(int projectId) async {
    Logs().d('ProjectRemoteDataSource: getTasks projectId=$projectId');
    try {
      final req = projectpb.GetTasksRequest(projectId: Int64(projectId));
      final resp = await _authGuard.execute(() => _client.getTasks(req));

      return TaskMapper.listFromProto(resp.tasks, projectId: projectId);
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в getTasks', e);
      throwGrpcError(e, 'Ошибка получения задач');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в getTasks', e);
      throw ApiFailure('Ошибка получения задач');
    }
  }

  @override
  Future<Task> getTask(int taskId) async {
    Logs().d('ProjectRemoteDataSource: getTask taskId=$taskId');
    try {
      final req = projectpb.GetTaskRequest(taskId: Int64(taskId));
      final resp = await _authGuard.execute(() => _client.getTask(req));
      return TaskMapper.fromGetTaskResponse(resp, projectId: 0);
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в getTask', e);
      throwGrpcError(e, 'Ошибка получения задачи');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в getTask', e);
      throw ApiFailure('Ошибка получения задачи');
    }
  }

  @override
  Future<void> editTaskColumnId(int taskId, int columnId) async {
    Logs().d('ProjectRemoteDataSource: editTaskColumnId taskId=$taskId, columnId=$columnId');
    try {
      final req = projectpb.EditTaskColumnIdRequest(
        taskId: Int64(taskId),
        columnId: Int64(columnId),
      );
      await _authGuard.execute(() => _client.editTaskColumnId(req));
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в editTaskColumnId', e);
      throwGrpcError(e, 'Ошибка обновления колонки задачи');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в editTaskColumnId', e);
      throw ApiFailure('Ошибка обновления колонки задачи');
    }
  }

  @override
  Future<Task> editTask(
    int taskId,
    String name,
    String description,
    int assigner,
    int executor, {
    List<int>? labelIds,
  }) async {
    Logs().d('ProjectRemoteDataSource: editTask taskId=$taskId');
    try {
      final req = projectpb.EditTaskRequest(
        taskId: Int64(taskId),
        name: name,
        description: description,
        assigner: Int64(assigner),
        executor: Int64(executor),
        labelIds: (labelIds ?? []).map((id) => Int64(id)).toList(),
      );
      await _authGuard.execute(() => _client.editTask(req));
      final taskReq = projectpb.GetTaskRequest(taskId: Int64(taskId));
      final taskResp = await _authGuard.execute(() => _client.getTask(taskReq));
      return TaskMapper.fromGetTaskResponse(taskResp, projectId: 0);
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в editTask', e);
      throwGrpcError(e, 'Ошибка обновления задачи');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в editTask', e);
      throw ApiFailure('Ошибка обновления задачи');
    }
  }

  @override
  Future<void> deleteTask(int taskId) async {
    Logs().d('ProjectRemoteDataSource: deleteTask taskId=$taskId');
    try {
      final req = projectpb.DeleteTaskRequest(taskId: Int64(taskId));
      await _authGuard.execute(() => _client.deleteTask(req));
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в deleteTask', e);
      throwGrpcError(e, 'Ошибка удаления задачи');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в deleteTask', e);
      throw ApiFailure('Ошибка удаления задачи');
    }
  }

  @override
  Future<List<BoardColumn>> getProjectColumns(int projectId) async {
    Logs().d('ProjectRemoteDataSource: getProjectColumns projectId=$projectId');
    try {
      final req = projectpb.GetProjectColumnsRequest(projectId: Int64(projectId));
      final resp = await _authGuard.execute(() => _client.getProjectColumns(req));
      return BoardColumnMapper.listFromProto(resp.columns);
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в getProjectColumns', e);
      throwGrpcError(e, 'Ошибка загрузки колонок');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в getProjectColumns', e);
      throw ApiFailure('Ошибка загрузки колонок');
    }
  }

  @override
  Future<BoardColumn> createProjectColumn(
    int projectId,
    String title,
    String color, {
    String? statusKey,
  }) async {
    Logs().d('ProjectRemoteDataSource: createProjectColumn projectId=$projectId, title=$title');
    try {
      final req = projectpb.CreateProjectColumnRequest(
        projectId: Int64(projectId),
        title: title,
        color: color,
        statusKey: statusKey ?? '',
      );
      final resp = await _authGuard.execute(() => _client.createProjectColumn(req));
      final list = await getProjectColumns(projectId);
      try {
        return list.firstWhere((c) => c.id == resp.id.toInt());
      } catch (_) {}
      return BoardColumn(
        id: resp.id.toInt(),
        projectId: projectId,
        title: title,
        color: color,
        statusKey: statusKey ?? _slugFromTitle(title),
        position: list.length,
      );
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в createProjectColumn', e);
      throwGrpcError(e, 'Ошибка создания колонки');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в createProjectColumn', e);
      throw ApiFailure('Ошибка создания колонки');
    }
  }

  @override
  Future<void> editProjectColumn(
    int id, {
    String? title,
    String? color,
    String? statusKey,
    int? position,
  }) async {
    Logs().d('ProjectRemoteDataSource: editProjectColumn id=$id');
    try {
      final req = projectpb.EditProjectColumnRequest(
        id: Int64(id),
        title: title ?? '',
        color: color ?? '',
        statusKey: statusKey ?? '',
        position: position ?? -1,
      );
      await _authGuard.execute(() => _client.editProjectColumn(req));
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в editProjectColumn', e);
      throwGrpcError(e, 'Ошибка обновления колонки');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в editProjectColumn', e);
      throw ApiFailure('Ошибка обновления колонки');
    }
  }

  @override
  Future<void> deleteProjectColumn(int id) async {
    Logs().d('ProjectRemoteDataSource: deleteProjectColumn id=$id');
    try {
      final req = projectpb.DeleteProjectColumnRequest(id: Int64(id));
      await _authGuard.execute(() => _client.deleteProjectColumn(req));
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в deleteProjectColumn', e);
      final msg = e.message != null && e.message!.isNotEmpty
        ? e.message!
        : 'Ошибка удаления колонки';
      throwGrpcError(e, msg);
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в deleteProjectColumn', e);
      throw ApiFailure('Ошибка удаления колонки');
    }
  }

  @override
  Future<List<ProjectLabel>> getProjectLabels(int projectId) async {
    Logs().d('ProjectRemoteDataSource: getProjectLabels projectId=$projectId');
    try {
      final req = projectpb.GetProjectLabelsRequest(projectId: Int64(projectId));
      final resp = await _authGuard.execute(() => _client.getProjectLabels(req));
      return resp.items.map((l) => ProjectLabel(
        id: l.id.toInt(),
        name: l.name,
        color: l.color.isNotEmpty ? l.color : '#9E9E9E',
      )).toList();
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в getProjectLabels', e);
      throwGrpcError(e, 'Ошибка загрузки меток');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в getProjectLabels', e);
      throw ApiFailure('Ошибка загрузки меток');
    }
  }

  @override
  Future<ProjectLabel> createProjectLabel(
    int projectId,
    String name,
    String color,
  ) async {
    Logs().d('ProjectRemoteDataSource: createProjectLabel projectId=$projectId, name=$name');
    try {
      final req = projectpb.CreateProjectLabelRequest(
        projectId: Int64(projectId),
        name: name,
        color: color.isEmpty ? '#9E9E9E' : color,
      );
      final resp = await _authGuard.execute(() => _client.createProjectLabel(req));
      return ProjectLabel(id: resp.id.toInt(), name: name, color: color.isEmpty ? '#9E9E9E' : color);
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в createProjectLabel', e);
      throwGrpcError(e, 'Ошибка создания метки');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в createProjectLabel', e);
      throw ApiFailure('Ошибка создания метки');
    }
  }

  @override
  Future<void> updateProjectLabel(
    int id, {
    String? name,
    String? color,
  }) async {
    Logs().d('ProjectRemoteDataSource: updateProjectLabel id=$id');
    try {
      final req = projectpb.UpdateProjectLabelRequest(
        id: Int64(id),
        name: name ?? '',
        color: color ?? '',
      );
      await _authGuard.execute(() => _client.updateProjectLabel(req));
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в updateProjectLabel', e);
      throwGrpcError(e, 'Ошибка обновления метки');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в updateProjectLabel', e);
      throw ApiFailure('Ошибка обновления метки');
    }
  }

  @override
  Future<void> deleteProjectLabel(int id) async {
    Logs().d('ProjectRemoteDataSource: deleteProjectLabel id=$id');
    try {
      final req = projectpb.DeleteProjectLabelRequest(id: Int64(id));
      await _authGuard.execute(() => _client.deleteProjectLabel(req));
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в deleteProjectLabel', e);
      throwGrpcError(e, 'Ошибка удаления метки');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в deleteProjectLabel', e);
      throw ApiFailure('Ошибка удаления метки');
    }
  }

  @override
  Future<List<TaskComment>> getTaskComments(int taskId) async {
    Logs().d('ProjectRemoteDataSource: getTaskComments taskId=$taskId');
    try {
      final req = projectpb.GetTaskCommentsRequest(taskId: Int64(taskId));
      final resp = await _authGuard.execute(() => _client.getTaskComments(req));
      return resp.comments.map((c) {
        final atts = c.attachments.map((a) => TaskAttachment(
          fileId: a.fileId.toInt(),
          filename: a.filename,
          mimeType: a.mimeType,
          size: a.size.toInt(),
        ))
        .toList();
        return TaskComment(
          id: c.id.toInt(),
          taskId: c.taskId.toInt(),
          userId: c.userId.toInt(),
          body: c.body,
          createdAt: c.createdAt.toInt(),
          attachments: atts,
        );
      }).toList();
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в getTaskComments', e);
      throwGrpcError(e, 'Ошибка загрузки комментариев');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в getTaskComments', e);
      throw ApiFailure('Ошибка загрузки комментариев');
    }
  }

  @override
  Future<void> addTaskComment(
    int taskId,
    String body, {
    List<int> attachmentFileIds = const [],
  }) async {
    Logs().d('ProjectRemoteDataSource: addTaskComment taskId=$taskId');
    try {
      final attachments = attachmentFileIds.map((fileId) => projectpb.TaskAttachmentUpload(
        fileId: Int64(fileId),
        filename: '',
      ))
      .toList();
      final req = projectpb.AddTaskCommentRequest(
        taskId: Int64(taskId),
        body: body,
        attachments: attachments,
      );
      await _authGuard.execute(() => _client.addTaskComment(req));
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в addTaskComment', e);
      throwGrpcError(e, 'Ошибка добавления комментария');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в addTaskComment', e);
      throw ApiFailure('Ошибка добавления комментария');
    }
  }

  @override
  Future<List<ProjectActivity>> getProjectHistory(int projectId) async {
    Logs().d('ProjectRemoteDataSource: getProjectHistory projectId=$projectId');
    try {
      final req = projectpb.GetProjectHistoryRequest(projectId: Int64(projectId));
      final resp = await _authGuard.execute(() => _client.getProjectHistory(req));
      return resp.items.map((a) => ProjectActivity(
        id: a.id.toInt(),
        projectId: a.projectId.toInt(),
        taskId: a.taskId.toInt(),
        userId: a.userId.toInt(),
        action: a.action,
        payload: a.payload,
        createdAt: a.createdAt.toInt(),
      ))
      .toList();
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в getProjectHistory', e);
      throwGrpcError(e, 'Ошибка загрузки истории');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в getProjectHistory', e);
      throw ApiFailure('Ошибка загрузки истории');
    }
  }

  @override
  Future<List<ProjectActivity>> getTaskHistory(int taskId) async {
    Logs().d('ProjectRemoteDataSource: getTaskHistory taskId=$taskId');
    try {
      final req = projectpb.GetTaskHistoryRequest(taskId: Int64(taskId));
      final resp = await _authGuard.execute(() => _client.getTaskHistory(req));
      return resp.items.map((a) => ProjectActivity(
        id: a.id.toInt(),
        projectId: a.projectId.toInt(),
        taskId: a.taskId.toInt(),
        userId: a.userId.toInt(),
        action: a.action,
        payload: a.payload,
        createdAt: a.createdAt.toInt(),
      )).toList();
    } on GrpcError catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка gRPC в getTaskHistory', e);
      throwGrpcError(e, 'Ошибка загрузки истории задачи');
    } catch (e) {
      Logs().e('ProjectRemoteDataSource: ошибка в getTaskHistory', e);
      throw ApiFailure('Ошибка загрузки истории задачи');
    }
  }

  static String _slugFromTitle(String title) {
    final sb = StringBuffer();
    for (var i = 0; i < title.length; i++) {
      final r = title.codeUnitAt(i);
      if (r >= 0x61 && r <= 0x7a || r >= 0x30 && r <= 0x39) {
        sb.writeCharCode(r);
      } else if (r >= 0x41 && r <= 0x5a) {
        sb.writeCharCode(r + 32);
      } else if (r == 0x20 || r == 0x2d || r == 0x5f) {
        if (sb.length > 0 && sb.toString().codeUnitAt(sb.length - 1) != 0x5f) {
          sb.writeCharCode(0x5f);
        }
      }
    }
    var s = sb.toString();

    if (s.isEmpty) {
      return 'column';
    }

    if (s.codeUnitAt(s.length - 1) == 0x5f) {
      s = s.substring(0, s.length - 1);
    }

    return s;
  }
}
