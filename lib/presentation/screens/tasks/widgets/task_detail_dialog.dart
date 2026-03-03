import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/layout/responsive.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/domain/entities/task.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:voosu/presentation/screens/tasks/bloc/task_bloc.dart';
import 'package:voosu/presentation/screens/tasks/bloc/task_event.dart';
import 'package:voosu/presentation/screens/tasks/bloc/task_state.dart';
import 'package:voosu/presentation/screens/tasks/widgets/task_detail_view.dart';
import 'package:voosu/presentation/screens/tasks/widgets/task_edit_dialog.dart';

class TaskDetailDialog extends StatefulWidget {
  final Task task;

  const TaskDetailDialog({super.key, required this.task});

  static Future<void> show(BuildContext context, Task task) {
    final isMobile = Breakpoints.isMobile(context);
    final size = MediaQuery.sizeOf(context);

    ProjectBloc? projectBloc;
    TaskBloc? taskBloc;
    try {
      projectBloc = context.read<ProjectBloc>();
    } catch (e) {
      Logs().d('TaskDetailDialog: ProjectBloc', e);
    }
    try {
      taskBloc = context.read<TaskBloc>();
    } catch (e) {
      Logs().d('TaskDetailDialog: TaskBloc', e);
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      useSafeArea: isMobile,
      builder: (dialogContext) {
        Widget dialogContent = TaskDetailDialog(task: task);
        if (projectBloc != null) {
          dialogContent = BlocProvider<ProjectBloc>.value(
            value: projectBloc,
            child: dialogContent,
          );
        }
        if (taskBloc != null) {
          dialogContent = BlocProvider<TaskBloc>.value(
            value: taskBloc,
            child: dialogContent,
          );
        }

        return Dialog(
          insetPadding: isMobile
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: ConstrainedBox(
            constraints: isMobile
              ? BoxConstraints.tight(size)
              : const BoxConstraints(
                maxWidth: 800,
                maxHeight: 700,
              ),
            child: dialogContent,
          ),
        );
      },
    );
  }

  @override
  State<TaskDetailDialog> createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends State<TaskDetailDialog> {
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Future<void> _openEdit() async {
    final taskBloc = context.read<TaskBloc>();
    final projectBloc = context.read<ProjectBloc>();
    final updated = await TaskEditDialog.show(
      context,
      _task,
      taskBloc: taskBloc,
      projectBloc: projectBloc,
    );
    if (updated != null && mounted) {
      setState(() => _task = updated);
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: Text('Задача "${_task.name}" будет удалена без возможности восстановления.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<TaskBloc>().add(TaskDeleteRequested(_task.id));
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final theme = Theme.of(context);

    return BlocListener<TaskBloc, TaskState>(
      listenWhen: (prev, next) => next.selectedTask?.id == widget.task.id && prev.selectedTask != next.selectedTask,
      listener: (context, state) {
        if (state.selectedTask?.id == widget.task.id && mounted) {
          setState(() => _task = state.selectedTask!);
        }
      },
      child: BlocBuilder<TaskBloc, TaskState>(
        buildWhen: (prev, next) => prev.selectedTask?.id != next.selectedTask?.id && next.selectedTask?.id == widget.task.id,
        builder: (context, state) {
          final currentTask = state.selectedTask?.id == widget.task.id
            ? state.selectedTask!
            : _task;
          return Material(
            borderRadius: BorderRadius.circular(isMobile ? 0 : 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Детали задачи',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: _openEdit,
                        tooltip: 'Редактировать',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: _deleteTask,
                        tooltip: 'Удалить',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          context.read<TaskBloc>().add(const TaskClearSelection());
                          Navigator.of(context).pop();
                        },
                        tooltip: 'Закрыть',
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: TaskDetailView(
                      task: currentTask,
                      projectId: currentTask.projectId,
                      onBack: () {
                        context.read<TaskBloc>().add(const TaskClearSelection());
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
