import 'package:voosu/domain/entities/project.dart';

abstract class ProjectRepository {
  Future<Project> createProject(String name);

  Future<List<Project>> getProjects();

  Future<Project> getProject(int id);

  Future<void> updateProject(int projectId, String name);
}
