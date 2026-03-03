import 'package:voosu/domain/entities/board_column.dart';
import 'package:voosu/domain/repositories/project_repository.dart';

class CreateProjectColumnUseCase {
  final ProjectRepository repo;

  CreateProjectColumnUseCase(this.repo);

  Future<BoardColumn> call(
    int projectId,
    String title,
    String color, {
    String? statusKey,
  }) => repo.createProjectColumn(projectId, title, color, statusKey: statusKey);
}
