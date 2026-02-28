import 'package:equatable/equatable.dart';
import 'package:voosu/domain/entities/project.dart';

class ProjectState extends Equatable {
  final bool isLoading;
  final List<Project> projects;
  final Project? selectedProject;
  final String? error;

  const ProjectState({
    this.isLoading = false,
    this.projects = const [],
    this.selectedProject,
    this.error,
  });

  ProjectState copyWith({
    bool? isLoading,
    List<Project>? projects,
    Project? selectedProject,
    bool clearSelectedProject = false,
    String? error,
  }) {
    return ProjectState(
      isLoading: isLoading ?? this.isLoading,
      projects: projects ?? this.projects,
      selectedProject: clearSelectedProject
          ? null
          : (selectedProject ?? this.selectedProject),
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, projects, selectedProject, error];
}
