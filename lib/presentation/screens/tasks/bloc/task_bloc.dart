import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/domain/usecases/project/create_task_usecase.dart';
import 'package:voosu/domain/usecases/project/get_tasks_usecase.dart';
import 'package:voosu/domain/usecases/project/edit_task_column_id_usecase.dart';
import 'package:voosu/domain/usecases/project/edit_task_usecase.dart';
import 'package:voosu/domain/usecases/project/delete_task_usecase.dart';
import 'package:voosu/presentation/screens/tasks/bloc/task_event.dart';
import 'package:voosu/presentation/screens/tasks/bloc/task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasksUseCase getTasksUseCase;
  final CreateTaskUseCase createTaskUseCase;
  final EditTaskColumnIdUseCase editTaskColumnIdUseCase;
  final EditTaskUseCase editTaskUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;

  TaskBloc({
    required this.getTasksUseCase,
    required this.createTaskUseCase,
    required this.editTaskColumnIdUseCase,
    required this.editTaskUseCase,
    required this.deleteTaskUseCase,
  }) : super(const TaskState()) {
    on<TasksLoadRequested>(_onLoadRequested);
    on<TaskCreateRequested>(_onCreateRequested);
    on<TaskEditRequested>(_onEditRequested);
    on<TaskDeleteRequested>(_onDeleteRequested);
    on<TaskColumnIdEditRequested>(_onColumnIdEditRequested);
    on<TaskUpdatedFromSync>(_onTaskUpdatedFromSync);
    on<TaskSelected>(_onSelected);
    on<TaskClearSelection>(_onClearSelection);
    on<TaskClearError>(_onClearError);
  }

  Future<void> _onLoadRequested(
    TasksLoadRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(
      state.copyWith(isLoading: true, error: null, projectId: event.projectId),
    );
    try {
      final tasks = await getTasksUseCase(event.projectId);
      emit(state.copyWith(isLoading: false, tasks: tasks));
    } catch (e) {
      Logs().e('TaskBloc: ошибка загрузки задач', e);
      emit(state.copyWith(isLoading: false, error: 'Ошибка загрузки задач'));
    }
  }

  Future<void> _onCreateRequested(
    TaskCreateRequested event,
    Emitter<TaskState> emit,
  ) async {
    final name = event.name.trim();
    if (name.isEmpty) return;

    emit(state.copyWith(isLoading: true, error: null));
    try {
      final task = await createTaskUseCase(
        event.projectId,
        name,
        event.description,
        event.executor,
        attachmentFileIds: event.attachmentFileIds,
        labelIds: event.labelIds,
      );
      final tasks = [...state.tasks, task];
      emit(state.copyWith(isLoading: false, tasks: tasks));
      add(TasksLoadRequested(event.projectId));
    } catch (e) {
      Logs().e('TaskBloc: ошибка создания задачи', e);
      emit(state.copyWith(isLoading: false, error: 'Ошибка создания задачи'));
    }
  }

  Future<void> _onEditRequested(
    TaskEditRequested event,
    Emitter<TaskState> emit,
  ) async {
    final name = event.name.trim();
    if (name.isEmpty) return;

    emit(state.copyWith(isLoading: true, error: null));
    try {
      final edit = await editTaskUseCase(
        event.taskId,
        name,
        event.description,
        event.assigner,
        event.executor,
        labelIds: event.labelIds,
      );
      final projectId = state.projectId;
      final editWithProject = projectId != null
          ? edit.copyWith(projectId: projectId)
          : edit;
      final tasks = state.tasks
          .map((t) => t.id == event.taskId ? editWithProject : t)
          .toList();
      emit(state.copyWith(isLoading: false, tasks: tasks));
    } catch (e) {
      Logs().e('TaskBloc: ошибка обновления задачи', e);
      emit(state.copyWith(isLoading: false, error: 'Ошибка обновления задачи'));
    }
  }

  Future<void> _onDeleteRequested(
    TaskDeleteRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await deleteTaskUseCase(event.taskId);
      final tasks = state.tasks.where((t) => t.id != event.taskId).toList();
      final clearSelected = state.selectedTask?.id == event.taskId;
      emit(state.copyWith(
        isLoading: false,
        tasks: tasks,
        clearSelectedTask: clearSelected,
      ));
    } catch (e) {
      Logs().e('TaskBloc: ошибка удаления задачи', e);
      emit(state.copyWith(isLoading: false, error: 'Ошибка удаления задачи'));
    }
  }

  void _onSelected(TaskSelected event, Emitter<TaskState> emit) {
    emit(state.copyWith(selectedTask: event.task));
  }

  void _onClearSelection(TaskClearSelection event, Emitter<TaskState> emit) {
    emit(state.copyWith(clearSelectedTask: true));
  }

  Future<void> _onColumnIdEditRequested(
    TaskColumnIdEditRequested event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await editTaskColumnIdUseCase(event.taskId, event.columnId);
      final editTasks = state.tasks.map((task) {
        if (task.id == event.taskId) {
          return task.copyWith(columnId: event.columnId);
        }
        return task;
      }).toList();
      emit(state.copyWith(tasks: editTasks));

      if (state.projectId != null) {
        add(TasksLoadRequested(state.projectId!));
      }
    } catch (e) {
      Logs().e('TaskBloc: ошибка обновления колонки задачи', e);
      emit(state.copyWith(error: 'Ошибка обновления колонки задачи'));
    }
  }

  void _onClearError(TaskClearError event, Emitter<TaskState> emit) {
    emit(state.copyWith(error: null));
  }

  void _onTaskUpdatedFromSync(
    TaskUpdatedFromSync event,
    Emitter<TaskState> emit,
  ) {
    if (state.projectId != event.projectId) {
      return;
    }

    final taskWithProject = event.task.projectId != 0
      ? event.task
      : event.task.copyWith(projectId: event.projectId);
    final hasTask = state.tasks.any((t) => t.id == taskWithProject.id);
    final tasks = hasTask
      ? state.tasks
        .map((t) => t.id == taskWithProject.id ? taskWithProject : t)
        .toList()
      : [...state.tasks, taskWithProject];
    final selectedTask = state.selectedTask?.id == taskWithProject.id
      ? taskWithProject
      : state.selectedTask;
    emit(state.copyWith(
      tasks: tasks,
      selectedTask: selectedTask,
    ));
  }
}
