import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/injector.dart';
import 'package:voosu/domain/entities/project.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_event.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_state.dart';
import 'package:voosu/presentation/screens/projects/project_history_dialog.dart';
import 'package:voosu/presentation/screens/projects/project_members_dialog.dart';
import 'package:voosu/presentation/screens/tasks/bloc/task_bloc.dart';
import 'package:voosu/presentation/screens/tasks/bloc/task_event.dart';
import 'package:voosu/presentation/screens/tasks/tasks_screen.dart';
import 'package:voosu/presentation/screens/tasks/widgets/columns_manage_dialog.dart';
import 'package:voosu/presentation/screens/tasks/widgets/labels_manage_dialog.dart';
import 'package:voosu/presentation/screens/tasks/widgets/task_create_dialog.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  void Function()? _refreshColumns;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectBloc>().add(ProjectSelected(widget.project));
    });
  }

  void _onRegisterRefresh(void Function()? refresh) {
    _refreshColumns = refresh;
  }

  void _openColumns() {
    ColumnsManageDialog.show(
      context,
      projectId: widget.project.id,
      onClosed: () => _refreshColumns?.call(),
    );
  }

  void _openLabels() {
    LabelsManageDialog.show(
      context,
      projectId: widget.project.id,
    );
  }

  void _openCreateTask(BuildContext contextWithTaskBloc) {
    final taskBloc = contextWithTaskBloc.read<TaskBloc>();
    ProjectBloc? projectBloc;
    int? currentUserId;
    try {
      projectBloc = context.read<ProjectBloc>();
    } catch (_) {}
    try {
      currentUserId = context.read<AuthBloc>().state.user?.id;
    } catch (_) {}
    showDialog<void>(
      context: contextWithTaskBloc,
      builder: (ctx) {
        Widget dialog = BlocProvider.value(
          value: taskBloc,
          child: TaskCreateDialog(
            projectId: widget.project.id,
            onCreated: () {
              contextWithTaskBloc.read<TaskBloc>().add(
                TasksLoadRequested(widget.project.id),
              );
            },
            initialExecutorUserId: currentUserId,
          ),
        );
        if (projectBloc != null) {
          dialog = BlocProvider.value(value: projectBloc, child: dialog);
        }

        return dialog;
      },
    );
  }

  void _openMembers() {
    ProjectMembersDialog.show(context, project: widget.project);
  }

  void _openHistory() {
    ProjectHistoryDialog.show(context, projectId: widget.project.id);
  }

  void _openEditName() {
    final bloc = context.read<ProjectBloc>();
    final project = bloc.state.selectedProject?.id == widget.project.id
        ? bloc.state.selectedProject!
        : widget.project;
    final controller = TextEditingController(text: project.name);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Переименовать проект'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Название',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (_) => Navigator.of(ctx).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                bloc.add(ProjectUpdateNameRequested(widget.project.id, name));
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<TaskBloc>(),
      child: Builder(
        builder: (contextWithTaskBloc) {
          return BlocBuilder<ProjectBloc, ProjectState>(
            buildWhen: (a, b) => a.selectedProject != b.selectedProject,
            builder: (context, projectState) {
              final project =
                  projectState.selectedProject?.id == widget.project.id
                  ? projectState.selectedProject!
                  : widget.project;
              return Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    FilledButton.icon(
                      onPressed: () => _openCreateTask(contextWithTaskBloc),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Создать задачу'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.view_column),
                      tooltip: 'Колонки',
                      onPressed: _openColumns,
                    ),
                    IconButton(
                      icon: const Icon(Icons.label_outline),
                      tooltip: 'Метки',
                      onPressed: _openLabels,
                    ),
                    IconButton(
                      icon: const Icon(Icons.history),
                      tooltip: 'История',
                      onPressed: _openHistory,
                    ),
                    IconButton(
                      icon: const Icon(Icons.people),
                      tooltip: 'Участники проекта',
                      onPressed: _openMembers,
                    ),
                    if (project.isCurrentUserAdmin)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Переименовать проект',
                        onPressed: _openEditName,
                      ),
                  ],
                ),
                body: BlocProvider.value(
                  value: contextWithTaskBloc.read<TaskBloc>(),
                  child: TasksScreen(
                    project: project,
                    onRegisterRefresh: _onRegisterRefresh,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
