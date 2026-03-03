import 'package:voosu/domain/repositories/project_repository.dart';

class DeleteProjectColumnUseCase {
  final ProjectRepository repo;

  DeleteProjectColumnUseCase(this.repo);

  Future<void> call(int id) => repo.deleteProjectColumn(id);
}
