import 'package:voosu/domain/entities/project.dart';
import 'package:voosu/domain/entities/project_activity.dart';
import 'package:voosu/domain/entities/project_member_item.dart';

abstract class ProjectRepository {
  Future<Project> createProject(String name);

  Future<List<Project>> getProjects();

  Future<Project> getProject(int id);

  Future<void> updateProject(int projectId, String name);

  Future<void> addUserToProject(int projectId, List<int> userIds);

  Future<void> removeUserFromProject(int projectId, int userId);

  Future<List<ProjectMemberItem>> getProjectMembers(int projectId);

  Future<List<ProjectActivity>> getProjectHistory(int projectId);
}
