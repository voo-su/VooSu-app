import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:voosu/core/auth_guard.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/grpc_channel_manager.dart';
import 'package:voosu/core/grpc_error_handler.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/mappers/project_mapper.dart';
import 'package:voosu/domain/entities/project.dart';
import 'package:voosu/domain/entities/project_activity.dart';
import 'package:voosu/domain/entities/project_member_item.dart';
import 'package:voosu/generated/grpc_pb/project.pbgrpc.dart' as projectpb;

abstract class IProjectRemoteDataSource {
  Future<Project> createProject(String name);

  Future<List<Project>> getProjects();

  Future<Project> getProject(int id);

  Future<void> updateProject(int projectId, String name);

  Future<void> addUserToProject(int projectId, List<int> userIds);

  Future<void> removeUserFromProject(int projectId, int userId);

  Future<List<ProjectMemberItem>> getProjectMembers(int projectId);

  Future<List<ProjectActivity>> getProjectHistory(int projectId);
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
}
