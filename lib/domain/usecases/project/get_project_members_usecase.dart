import 'package:voosu/domain/entities/project_member_item.dart';
import 'package:voosu/domain/repositories/project_repository.dart';

class GetProjectMembersUseCase {
  final ProjectRepository repo;

  GetProjectMembersUseCase(this.repo);

  Future<List<ProjectMemberItem>> call(int projectId) => repo.getProjectMembers(projectId);
}
