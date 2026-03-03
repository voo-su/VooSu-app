import 'package:voosu/domain/repositories/project_repository.dart';

class UpdateProjectLabelUseCase {
  final ProjectRepository repo;

  UpdateProjectLabelUseCase(this.repo);

  Future<void> call(
    int id, {
    String? name,
    String? color,
  }) => repo.updateProjectLabel(id, name: name, color: color);
}
