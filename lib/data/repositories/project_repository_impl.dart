import 'package:voosu/core/failures.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/data_sources/remote/project_remote_datasource.dart';
import 'package:voosu/domain/entities/board_column.dart';
import 'package:voosu/domain/entities/project.dart';
import 'package:voosu/domain/entities/project_activity.dart';
import 'package:voosu/domain/entities/project_label.dart';
import 'package:voosu/domain/entities/project_member_item.dart';
import 'package:voosu/domain/entities/task.dart';
import 'package:voosu/domain/entities/task_comment.dart';
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
  Future<Task> createTask(
    int projectId,
    String name,
    String description,
    int executor, {
    List<int> attachmentFileIds = const [],
    List<int> labelIds = const [],
  }) async {
    try {
      return await _remote.createTask(
        projectId,
        name,
        description,
        executor,
        attachmentFileIds: attachmentFileIds,
        labelIds: labelIds,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в createTask', e);
      throw ApiFailure('Ошибка создания задачи');
    }
  }

  @override
  Future<List<Task>> getTasks(int projectId) async {
    try {
      return await _remote.getTasks(projectId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getTasks', e);
      throw ApiFailure('Ошибка получения задач');
    }
  }

  @override
  Future<Task> getTask(int taskId) async {
    try {
      return await _remote.getTask(taskId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getTask', e);
      throw ApiFailure('Ошибка получения задачи');
    }
  }

  @override
  Future<void> editTaskColumnId(int taskId, int columnId) async {
    try {
      return await _remote.editTaskColumnId(taskId, columnId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в editTaskColumnId', e);
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
    try {
      return await _remote.editTask(
        taskId,
        name,
        description,
        assigner,
        executor,
        labelIds: labelIds,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в editTask', e);
      throw ApiFailure('Ошибка обновления задачи');
    }
  }

  @override
  Future<void> deleteTask(int taskId) async {
    try {
      return await _remote.deleteTask(taskId);
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      Logs().e('ProjectRepository: неожиданная ошибка в deleteTask', e);
      throw ApiFailure('Ошибка удаления задачи');
    }
  }

  @override
  Future<List<BoardColumn>> getProjectColumns(int projectId) async {
    try {
      return await _remote.getProjectColumns(projectId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getProjectColumns', e);
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
    try {
      return await _remote.createProjectColumn(
        projectId,
        title,
        color,
        statusKey: statusKey,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в createProjectColumn', e);
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
    try {
      return await _remote.editProjectColumn(
        id,
        title: title,
        color: color,
        statusKey: statusKey,
        position: position,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в editProjectColumn', e);
      throw ApiFailure('Ошибка обновления колонки');
    }
  }

  @override
  Future<void> deleteProjectColumn(int id) async {
    try {
      return await _remote.deleteProjectColumn(id);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в deleteProjectColumn', e);
      throw ApiFailure('Ошибка удаления колонки');
    }
  }

  @override
  Future<List<ProjectLabel>> getProjectLabels(int projectId) async {
    try {
      return await _remote.getProjectLabels(projectId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getProjectLabels', e);
      throw ApiFailure('Ошибка загрузки меток');
    }
  }

  @override
  Future<ProjectLabel> createProjectLabel(
    int projectId,
    String name,
    String color,
  ) async {
    try {
      return await _remote.createProjectLabel(projectId, name, color);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в createProjectLabel', e);
      throw ApiFailure('Ошибка создания метки');
    }
  }

  @override
  Future<void> updateProjectLabel(
    int id, {
    String? name,
    String? color,
  }) async {
    try {
      return await _remote.updateProjectLabel(id, name: name, color: color);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в updateProjectLabel', e);
      throw ApiFailure('Ошибка обновления метки');
    }
  }

  @override
  Future<void> deleteProjectLabel(int id) async {
    try {
      return await _remote.deleteProjectLabel(id);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в deleteProjectLabel', e);
      throw ApiFailure('Ошибка удаления метки');
    }
  }

  @override
  Future<List<TaskComment>> getTaskComments(int taskId) async {
    try {
      return await _remote.getTaskComments(taskId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getTaskComments', e);
      throw ApiFailure('Ошибка загрузки комментариев');
    }
  }

  @override
  Future<void> addTaskComment(
    int taskId,
    String body,
    {List<int> attachmentFileIds = const []}
  ) async {
    try {
      return await _remote.addTaskComment(
        taskId,
        body,
        attachmentFileIds: attachmentFileIds,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в addTaskComment', e);
      throw ApiFailure('Ошибка добавления комментария');
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

  @override
  Future<List<ProjectActivity>> getTaskHistory(int taskId) async {
    try {
      return await _remote.getTaskHistory(taskId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('ProjectRepository: неожиданная ошибка в getTaskHistory', e);
      throw ApiFailure('Ошибка загрузки истории задачи');
    }
  }
}
