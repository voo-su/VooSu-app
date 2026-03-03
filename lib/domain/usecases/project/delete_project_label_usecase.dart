import 'package:voosu/domain/repositories/project_repository.dart';

class DeleteProjectLabelUseCase {
  final ProjectRepository repo;

  DeleteProjectLabelUseCase(this.repo);

  Future<void> call(int id) => repo.deleteProjectLabel(id);
}
