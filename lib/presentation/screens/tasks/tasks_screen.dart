import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/core/util.dart';
import 'package:voosu/core/snackbar_ext.dart';
import 'package:voosu/domain/entities/board_column.dart';
import 'package:voosu/domain/entities/project.dart';
import 'package:voosu/domain/entities/project_label.dart';
import 'package:voosu/domain/entities/task.dart';
import 'package:voosu/domain/entities/task_update_payload.dart';
import 'package:voosu/domain/usecases/project/get_project_columns_usecase.dart';
import 'package:voosu/domain/usecases/project/get_project_labels_usecase.dart';
import 'package:voosu/domain/usecases/project/get_project_members_usecase.dart';
import 'package:voosu/presentation/screens/tasks/bloc/task_bloc.dart';
import 'package:voosu/presentation/screens/tasks/bloc/task_event.dart';
import 'package:voosu/presentation/screens/tasks/bloc/task_state.dart';
import 'package:voosu/presentation/screens/tasks/widgets/board.dart';
import 'package:voosu/presentation/screens/tasks/widgets/task_detail_dialog.dart';
import 'package:voosu/presentation/widgets/loading_placeholder.dart';

class TasksScreen extends StatefulWidget {
  final Project project;

  final void Function(void Function()? refresh)? onRegisterRefresh;

  const TasksScreen({super.key, required this.project, this.onRegisterRefresh});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<BoardColumn>? _columns;
  List<ProjectLabel> _projectLabels = [];
  final Set<int> _filterLabelIds = {};
  Map<int, String> _executorNames = {};
  StreamSubscription<TaskUpdatePayload>? _taskUpdateSubscription;

  @override
  void initState() {
    super.initState();
    widget.onRegisterRefresh?.call(_loadColumns);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskBloc>().add(TasksLoadRequested(widget.project.id));
      _loadColumns();
      _loadLabels();
      _loadExecutorNames();
      _taskUpdateSubscription = di.sl<StreamController<TaskUpdatePayload>>().stream.listen((payload) {
        if (payload.projectId != widget.project.id || !mounted) {
          return;
        }
        final bloc = context.read<TaskBloc>();
        if (payload.task != null) {
          bloc.add(TaskUpdatedFromSync(
            projectId: payload.projectId,
            task: payload.task!,
          ));
        } else {
          bloc.add(TasksLoadRequested(payload.projectId));
        }
      });
    });
  }

  Future<void> _loadLabels() async {
    try {
      final list = await di.sl<GetProjectLabelsUseCase>()(widget.project.id);
      if (mounted) {
        setState(() => _projectLabels = list);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _projectLabels = []);
      }
    }
  }

  Future<void> _loadExecutorNames() async {
    try {
      final members = await di.sl<GetProjectMembersUseCase>()(widget.project.id);
      if (mounted) {
        final map = <int, String>{};
        for (final m in members) {
          final id = m.user.id;
          if (id != 0) map[id] = m.user.displayName;
        }

        setState(() => _executorNames = map);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _executorNames = {});
      }
    }
  }

  @override
  void dispose() {
    widget.onRegisterRefresh?.call(null);
    _taskUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadColumns() async {
    try {
      final list = await di.sl<GetProjectColumnsUseCase>()(widget.project.id);
      if (mounted) {
        setState(
          () =>
              _columns = list..sort((a, b) => a.position.compareTo(b.position)),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _columns = const []);
      }
    }
  }

  List<Task> _filterTasks(List<Task> tasks) {
    if (_filterLabelIds.isEmpty) {
      return tasks;
    }

    return tasks.where((t) {
      return t.labels.any((l) => _filterLabelIds.contains(l.id));
    }).toList();
  }

  Widget _buildView(TaskState state) {
    final filteredTasks = _filterTasks(state.tasks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_projectLabels.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: const Text('Все', style: TextStyle(fontSize: 12)),
                      selected: _filterLabelIds.isEmpty,
                      onSelected: (v) {
                        setState(() => _filterLabelIds.clear());
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      selectedColor: Theme.of(context).colorScheme.primaryContainer,
                      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  ..._projectLabels.map((label) {
                    final selected = _filterLabelIds.contains(label.id);
                    final color = labelColorFromHex(label.color);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(
                          label.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: selected ? color : null,
                          ),
                        ),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _filterLabelIds.add(label.id);
                            } else {
                              _filterLabelIds.remove(label.id);
                            }
                          });
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        selectedColor: color.withValues(alpha: 0.2),
                        checkmarkColor: color,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Expanded(
          child: state.isLoading && state.tasks.isEmpty
              ? const LoadingPlaceholder()
              : Board(
                  tasks: filteredTasks,
                  columns: _columns ?? const [],
                  executorNames: _executorNames,
                  onTaskTap: (task) {
                    context.read<TaskBloc>().add(TaskSelected(task));
                    TaskDetailDialog.show(context, task).then((_) {
                      if (mounted) {
                        context.read<TaskBloc>().add(const TaskClearSelection());
                      }
                    });
                  },
                  onTaskColumnIdChanged: (task, newColumnId) {
                    context.read<TaskBloc>().add(
                      TaskColumnIdEditRequested(
                        taskId: task.id,
                        columnId: newColumnId,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state.error != null) {
          context.showErrorSnackBar(state.error!);
          context.read<TaskBloc>().add(const TaskClearError());
        }
      },
      builder: (context, state) {
        return _buildView(state);
      },
    );
  }
}
