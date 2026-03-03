import 'package:voosu/domain/entities/board_column.dart';
import 'package:voosu/domain/entities/project.dart';
import 'package:voosu/domain/entities/project_activity.dart';
import 'package:voosu/domain/entities/project_label.dart';
import 'package:voosu/domain/entities/project_member_item.dart';
import 'package:voosu/domain/entities/task.dart';
import 'package:voosu/domain/entities/task_comment.dart';

abstract class ProjectRepository {
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
    int executor,
    {List<int>? labelIds}
  );

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
