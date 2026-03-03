import 'package:voosu/domain/repositories/project_repository.dart';

class EditProjectColumnUseCase {
  final ProjectRepository repo;

  EditProjectColumnUseCase(this.repo);

  Future<void> call(
    int id, {
    String? title,
    String? color,
    String? statusKey,
    int? position,
  }) => repo.editProjectColumn(
    id,
    title: title,
    color: color,
    statusKey: statusKey,
    position: position,
  );
}
