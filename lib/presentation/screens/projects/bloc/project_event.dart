import 'package:equatable/equatable.dart';
import 'package:voosu/domain/entities/project.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

class ProjectsStarted extends ProjectEvent {
  const ProjectsStarted();
}

class ProjectCreateRequested extends ProjectEvent {
  final String name;

  const ProjectCreateRequested(this.name);

  @override
  List<Object?> get props => [name];
}

class ProjectSelected extends ProjectEvent {
  final Project project;

  const ProjectSelected(this.project);

  @override
  List<Object?> get props => [project];
}

class ProjectUpdateNameRequested extends ProjectEvent {
  final int projectId;
  final String name;

  const ProjectUpdateNameRequested(this.projectId, this.name);

  @override
  List<Object?> get props => [projectId, name];
}

class ProjectClearSelection extends ProjectEvent {
  const ProjectClearSelection();
}

class ProjectClearError extends ProjectEvent {
  const ProjectClearError();
}
