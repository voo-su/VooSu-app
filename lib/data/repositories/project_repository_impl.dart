import 'package:voosu/core/failures.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/data_sources/remote/project_remote_datasource.dart';
import 'package:voosu/domain/entities/project.dart';
import 'package:voosu/domain/entities/project_activity.dart';
import 'package:voosu/domain/entities/project_member_item.dart';
import 'package:voosu/domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final IProjectRemoteDataSource _remote;

  ProjectRepositoryImpl(this._remote);

  @override
  Future<Project> createProject(String name) async {
    try {
      return await _remote.createProject(name);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в createProject', e);
      throw ApiFailure('Ошибка создания проекта');
    }
  }

  @override
  Future<List<Project>> getProjects() async {
    try {
      return await _remote.getProjects();
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getProjects', e);
      throw ApiFailure('Ошибка получения проектов');
    }
  }

  @override
  Future<Project> getProject(int id) async {
    try {
      return await _remote.getProject(id);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getProject', e);
      throw ApiFailure('Ошибка получения проекта');
    }
  }

  @override
  Future<void> updateProject(int projectId, String name) async {
    try {
      return await _remote.updateProject(projectId, name);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в updateProject', e);
      throw ApiFailure('Ошибка переименования проекта');
    }
  }

  @override
  Future<void> addUserToProject(int projectId, List<int> userIds) async {
    try {
      return await _remote.addUserToProject(projectId, userIds);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в addUserToProject', e);
      throw ApiFailure('Ошибка добавления участников');
    }
  }

  @override
  Future<void> removeUserFromProject(int projectId, int userId) async {
    try {
      return await _remote.removeUserFromProject(projectId, userId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в removeUserFromProject', e);
      throw ApiFailure('Ошибка удаления участника');
    }
  }

  @override
  Future<List<ProjectMemberItem>> getProjectMembers(int projectId) async {
    try {
      return await _remote.getProjectMembers(projectId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getProjectMembers', e);
      throw ApiFailure('Ошибка получения участников');
    }
  }

  @override
  Future<List<ProjectActivity>> getProjectHistory(int projectId) async {
    try {
      return await _remote.getProjectHistory(projectId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getProjectHistory', e);
      throw ApiFailure('Ошибка загрузки истории');
    }
  }
}
