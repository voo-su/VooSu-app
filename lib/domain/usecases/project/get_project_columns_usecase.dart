import 'package:voosu/domain/entities/board_column.dart';
import 'package:voosu/domain/repositories/project_repository.dart';

class GetProjectColumnsUseCase {
  final ProjectRepository repo;

  GetProjectColumnsUseCase(this.repo);

  Future<List<BoardColumn>> call(int projectId) => repo.getProjectColumns(projectId);
}
