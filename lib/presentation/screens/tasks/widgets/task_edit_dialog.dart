import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/core/util.dart';
import 'package:voosu/core/layout/responsive.dart';
import 'package:voosu/core/snackbar_ext.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/domain/entities/project_label.dart';
import 'package:voosu/domain/entities/task.dart';
import 'package:voosu/domain/entities/user.dart';
import 'package:voosu/domain/usecases/project/get_project_labels_usecase.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_event.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_state.dart';
import 'package:voosu/presentation/screens/tasks/bloc/task_bloc.dart';
import 'package:voosu/presentation/screens/tasks/bloc/task_event.dart';
import 'package:voosu/presentation/screens/tasks/bloc/task_state.dart';
import 'package:voosu/presentation/widgets/markdown_editor.dart';

class TaskEditDialog extends StatefulWidget {
  final Task task;
  final VoidCallback? onSaved;

  const TaskEditDialog({super.key, required this.task, this.onSaved});

  static Future<Task?> show(
    BuildContext context,
    Task task, {
    VoidCallback? onSaved,
    TaskBloc? taskBloc,
    ProjectBloc? projectBloc,
  }) {
    final isMobile = Breakpoints.isMobile(context);
    final maxWidth = isMobile ? double.infinity : 700.0;
    final maxHeight = isMobile ? double.infinity : 600.0;

    return showDialog<Task>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Widget content = TaskEditDialog(task: task, onSaved: onSaved);
        if (projectBloc != null) {
          content = BlocProvider<ProjectBloc>.value(
            value: projectBloc,
            child: content,
          );
        }
        if (taskBloc != null) {
          content = BlocProvider<TaskBloc>.value(
            value: taskBloc,
            child: content,
          );
        }
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 40,
            vertical: isMobile ? 16 : 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: content,
          ),
        );
      },
    );
  }

  @override
  State<TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isSubmitting = false;
  int? _selectedAssignerId;
  int? _selectedExecutorId;
  List<User> _members = [];
  List<ProjectLabel> _projectLabels = [];
  final Set<int> _selectedLabelIds = {};
  bool _waitingForResult = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task.name);
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    _selectedAssignerId = widget.task.assigner;
    _selectedExecutorId = widget.task.executor;
    _selectedLabelIds.addAll(widget.task.labels.map((l) => l.id));
    _loadMembers();
    _loadLabels();
  }

  Future<void> _loadLabels() async {
    try {
      final list = await di.sl<GetProjectLabelsUseCase>()(widget.task.projectId);
      if (mounted) {
        setState(() => _projectLabels = list);
      }
    } catch (_) {}
  }

  void _loadMembers() {
    try {
      final projectBloc = context.read<ProjectBloc>();
      projectBloc.add(ProjectMembersLoadRequested(widget.task.projectId));

      projectBloc.stream.listen((state) {
        if (state.members.isNotEmpty && mounted) {
          setState(() {
            _members = state.members.map((m) => m.user).toList();
            if (_selectedAssignerId != null && !_members.any((u) => u.id == _selectedAssignerId)) {
              if (_members.isNotEmpty) {
                _selectedAssignerId = _members.first.id;
              }
            }
            if (_selectedExecutorId != null && !_members.any((u) => u.id == _selectedExecutorId)) {
              if (_members.isNotEmpty) {
                _selectedExecutorId = _members.first.id;
              }
            }
          });
        }
      });
    } catch (e) {
      Logs().d('TaskEditDialog: _loadMembers', e);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAssignerId == null || _selectedExecutorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите постановщика и исполнителя'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
      _waitingForResult = true;
    });

    context.read<TaskBloc>().add(
      TaskEditRequested(
        taskId: widget.task.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        assigner: _selectedAssignerId!,
        executor: _selectedExecutorId!,
        labelIds: _selectedLabelIds.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (!_waitingForResult) return;
        if (state.error != null && _isSubmitting) {
          context.showErrorSnackBar(state.error!);
          setState(() {
            _isSubmitting = false;
            _waitingForResult = false;
          });
        } else if (!state.isLoading && _isSubmitting && state.error == null) {
          Task? updated;
          try {
            updated = state.tasks.firstWhere((t) => t.id == widget.task.id);
          } catch (_) {}

          if (updated != null) {
            widget.onSaved?.call();
            Navigator.of(context).pop(updated);
          }

          setState(() {
            _isSubmitting = false;
            _waitingForResult = false;
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Редактировать задачу',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  tooltip: 'Закрыть',
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название задачи',
                        border: OutlineInputBorder(),
                        hintText: 'Введите название задачи',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Название обязательно';
                        }

                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Описание',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    MarkdownEditor(
                      controller: _descriptionController,
                      hintText:
                          'Добавьте описание задачи (поддерживается Markdown)',
                      minLines: 6,
                      maxLines: 12,
                    ),
                    if (_projectLabels.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Метки',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _projectLabels.map((label) {
                          final selected = _selectedLabelIds.contains(label.id);
                          return FilterChip(
                            label: Text(label.name),
                            selected: selected,
                            onSelected: _isSubmitting
                              ? null
                              : (v) {
                                setState(() {
                                  if (v) {
                                    _selectedLabelIds.add(label.id);
                                  } else {
                                    _selectedLabelIds.remove(label.id);
                                  }
                                });
                              },
                            selectedColor: labelColorFromHex(label.color).withValues(alpha: 0.3),
                            checkmarkColor: labelColorFromHex(label.color),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Постановщик',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<ProjectBloc, ProjectState>(
                      builder: (context, projectState) {
                        if (projectState.isMembersLoading && _members.isEmpty) {
                          return const SizedBox(
                            height: 56,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return DropdownButtonFormField<int>(
                          initialValue: _selectedAssignerId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: _members
                              .map((user) {
                                final userId = user.id;
                                if (userId == 0) return null;
                                return DropdownMenuItem<int>(
                                  value: userId,
                                  child: Text(user.displayName),
                                );
                              })
                              .whereType<DropdownMenuItem<int>>()
                              .toList(),
                          onChanged: _isSubmitting
                              ? null
                              : (value) {
                                  setState(() => _selectedAssignerId = value);
                                },
                          validator: (value) {
                            if (value == null) return 'Выберите постановщика';
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Исполнитель',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<ProjectBloc, ProjectState>(
                      builder: (context, projectState) {
                        if (projectState.isMembersLoading && _members.isEmpty) {
                          return const SizedBox(
                            height: 56,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return DropdownButtonFormField<int>(
                          initialValue: _selectedExecutorId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: _members
                              .map((user) {
                                final userId = user.id;
                                if (userId == 0) {
                                  return null;
                                }
                                return DropdownMenuItem<int>(
                                  value: userId,
                                  child: Text(user.displayName),
                                );
                              })
                              .whereType<DropdownMenuItem<int>>()
                              .toList(),
                          onChanged: _isSubmitting
                              ? null
                              : (value) {
                                  setState(() => _selectedExecutorId = value);
                                },
                          validator: (value) {
                            if (value == null) return 'Выберите исполнителя';
                            return null;
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Сохранить'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
