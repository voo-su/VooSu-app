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

class ProjectMembersLoadRequested extends ProjectEvent {
  final int projectId;

  const ProjectMembersLoadRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class ProjectAddMembersRequested extends ProjectEvent {
  final int projectId;
  final List<int> userIds;

  const ProjectAddMembersRequested(this.projectId, this.userIds);

  @override
  List<Object?> get props => [projectId, userIds];
}

class ProjectUpdateNameRequested extends ProjectEvent {
  final int projectId;
  final String name;

  const ProjectUpdateNameRequested(this.projectId, this.name);

  @override
  List<Object?> get props => [projectId, name];
}

class ProjectRemoveMemberRequested extends ProjectEvent {
  final int projectId;
  final int userId;

  const ProjectRemoveMemberRequested(this.projectId, this.userId);

  @override
  List<Object?> get props => [projectId, userId];
}

class ProjectClearSelection extends ProjectEvent {
  const ProjectClearSelection();
}

class ProjectClearError extends ProjectEvent {
  const ProjectClearError();
}
