import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/domain/usecases/project/create_project_usecase.dart';
import 'package:voosu/domain/usecases/project/get_project_usecase.dart';
import 'package:voosu/domain/usecases/project/get_projects_usecase.dart';
import 'package:voosu/domain/usecases/project/update_project_usecase.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_event.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final GetProjectsUseCase getProjectsUseCase;
  final CreateProjectUseCase createProjectUseCase;
  final GetProjectUseCase getProjectUseCase;
  final UpdateProjectUseCase updateProjectUseCase;

  ProjectBloc({
    required this.getProjectsUseCase,
    required this.createProjectUseCase,
    required this.getProjectUseCase,
    required this.updateProjectUseCase,
  }) : super(const ProjectState()) {
    on<ProjectsStarted>(_onStarted);
    on<ProjectCreateRequested>(_onCreateRequested);
    on<ProjectSelected>(_onSelected);
    on<ProjectUpdateNameRequested>(_onUpdateNameRequested);
    on<ProjectClearSelection>(_onClearSelection);
    on<ProjectClearError>(_onClearError);
  }

  Future<void> _onStarted(
    ProjectsStarted event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final projects = await getProjectsUseCase();
      emit(state.copyWith(isLoading: false, projects: projects));
    } catch (e) {
      Logs().e('ProjectBloc: ошибка загрузки проектов', e);
      emit(state.copyWith(isLoading: false, error: 'Ошибка загрузки проектов'));
    }
  }

  Future<void> _onCreateRequested(
    ProjectCreateRequested event,
    Emitter<ProjectState> emit,
  ) async {
    final name = event.name.trim();
    if (name.isEmpty) return;

    emit(state.copyWith(isLoading: true, error: null));
    try {
      final project = await createProjectUseCase(name);
      final projects = [...state.projects, project];
      emit(
        state.copyWith(
          isLoading: false,
          projects: projects,
          selectedProject: project,
        ),
      );
    } catch (e) {
      Logs().e('ProjectBloc: ошибка создания проекта', e);
      emit(state.copyWith(isLoading: false, error: 'Ошибка создания проекта'));
    }
  }

  Future<void> _onSelected(
    ProjectSelected event,
    Emitter<ProjectState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedProject: event.project,
        error: null,
      ),
    );
    try {
      final projectWithRole = await getProjectUseCase(event.project.id);
      if (event.project.id != state.selectedProject?.id) {
        return;
      }

      emit(state.copyWith(selectedProject: projectWithRole));
    } catch (_) {}
  }

  Future<void> _onUpdateNameRequested(
    ProjectUpdateNameRequested event,
    Emitter<ProjectState> emit,
  ) async {
    final name = event.name.trim();
    if (name.isEmpty) {
      return;
    }

    emit(state.copyWith(error: null));
    try {
      await updateProjectUseCase(event.projectId, name);
      final updated = await getProjectUseCase(event.projectId);
      final projects = state.projects.map((p) {
        if (p.id == event.projectId) {
          return updated;
        }

        return p;
      }).toList();
      emit(
        state.copyWith(
          projects: projects,
          selectedProject: state.selectedProject?.id == event.projectId
              ? updated
              : state.selectedProject,
        ),
      );
    } catch (e) {
      Logs().e('ProjectBloc: ошибка переименования проекта', e);
      emit(state.copyWith(error: 'Ошибка переименования проекта'));
    }
  }

  void _onClearSelection(
    ProjectClearSelection event,
    Emitter<ProjectState> emit,
  ) {
    emit(state.copyWith(clearSelectedProject: true));
  }

  void _onClearError(ProjectClearError event, Emitter<ProjectState> emit) {
    emit(state.copyWith(error: null));
  }
}
