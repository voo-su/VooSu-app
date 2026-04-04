import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/core/util.dart';
import 'package:voosu/core/layout/responsive.dart';
import 'package:voosu/core/snackbar_ext.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/domain/entities/project_label.dart';
import 'package:voosu/domain/entities/user.dart';
import 'package:voosu/domain/usecases/project/get_project_labels_usecase.dart';
import 'package:voosu/domain/usecases/chat/upload_chat_file_usecase.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_event.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_state.dart';
import 'package:voosu/presentation/screens/tasks/bloc/task_bloc.dart';
import 'package:voosu/presentation/screens/tasks/bloc/task_event.dart';
import 'package:voosu/presentation/screens/tasks/bloc/task_state.dart';
import 'package:voosu/presentation/widgets/markdown_editor.dart';

class TaskCreateDialog extends StatefulWidget {
  final int projectId;
  final VoidCallback? onCreated;
  final int? initialExecutorUserId;

  const TaskCreateDialog({
    super.key,
    required this.projectId,
    this.onCreated,
    this.initialExecutorUserId,
  });

  @override
  State<TaskCreateDialog> createState() => _TaskCreateDialogState();
}

class _TaskCreateDialogState extends State<TaskCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  int? _selectedExecutorId;
  List<User> _members = [];
  List<ProjectLabel> _projectLabels = [];
  final Set<int> _selectedLabelIds = {};
  final List<({String fileId, String filename})> _attachments = [];
  bool _uploadingFile = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadLabels();
  }

  Future<void> _loadLabels() async {
    try {
      final list = await di.sl<GetProjectLabelsUseCase>()(widget.projectId);
      if (mounted) {
        setState(() => _projectLabels = list);
      }

    } catch (_) {}
  }

  void _loadMembers() {
    try {
      final projectBloc = context.read<ProjectBloc>();
      projectBloc.add(ProjectMembersLoadRequested(widget.projectId));

      projectBloc.stream.listen((state) {
        if (state.members.isNotEmpty && mounted) {
          setState(() {
            _members = state.members.map((m) => m.user).toList();
            if (_selectedExecutorId == null && _members.isNotEmpty) {
              final currentUserId = widget.initialExecutorUserId;
              if (currentUserId != null) {
                try {
                  final currentUser = _members.firstWhere(
                    (u) => u.id == currentUserId,
                  );
                  _selectedExecutorId = currentUser.id;
                } catch (_) {
                  _selectedExecutorId = _members.first.id;
                }
              } else {
                _selectedExecutorId = _members.first.id;
              }
            }
          });
        }
      });
    } catch (e) {
      Logs().d('TaskCreateDialog: _loadMembers', e);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }

    setState(() => _uploadingFile = true);
    for (final f in result.files) {
      if (f.path == null || f.name.isEmpty) {
        continue;
      }

      try {
        final bytes = await File(f.path!).readAsBytes();
        final fileId = await di.sl<UploadChatFileUseCase>().call(
          filename: f.name,
          chunkStream: Stream.fromIterable([bytes]),
          totalBytes: bytes.length,
        );
        if (mounted) {
          setState(() => _attachments.add((fileId: fileId, filename: f.name)));
        }
      } catch (_) {
        if (mounted) {
          context.showErrorSnackBar('Не удалось загрузить ${f.name}');
        }
      }
    }
    if (mounted) setState(() => _uploadingFile = false);
  }

  void _removeAttachment(int index) {
    setState(() => _attachments.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedExecutorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите ответственного'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    context.read<TaskBloc>().add(
      TaskCreateRequested(
        projectId: widget.projectId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        executor: _selectedExecutorId!,
        attachmentFileIds: _attachments
            .map((a) => int.tryParse(a.fileId))
            .whereType<int>()
            .toList(),
        labelIds: _selectedLabelIds.toList(),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      Navigator.of(context).pop();
      widget.onCreated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final maxWidth = isMobile ? double.infinity : 700.0;
    final maxHeight = isMobile ? double.infinity : 600.0;

    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state.error != null && _isSubmitting) {
          context.showErrorSnackBar(state.error!);
          setState(() => _isSubmitting = false);
        } else if (!state.isLoading && _isSubmitting && state.error == null) {
          Navigator.of(context).pop();
          widget.onCreated?.call();
          setState(() => _isSubmitting = false);
        }
      },
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40,
          vertical: isMobile ? 16 : 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
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
                        'Создать задачу',
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
                          autofocus: true,
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
                        if (_attachments.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: List.generate(_attachments.length, (i) {
                              final a = _attachments[i];
                              return Chip(
                                label: Text(a.filename),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: _isSubmitting
                                    ? null
                                    : () => _removeAttachment(i),
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                        ],
                        OutlinedButton.icon(
                          onPressed: _isSubmitting || _uploadingFile
                              ? null
                              : _pickAndUploadFile,
                          icon: _uploadingFile
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.attach_file),
                          label: const Text('Прикрепить файл'),
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
                          'Ответственный',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        BlocBuilder<ProjectBloc, ProjectState>(
                          builder: (context, projectState) {
                            if (projectState.isMembersLoading &&
                                _members.isEmpty) {
                              return const SizedBox(
                                height: 56,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
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
                                      setState(() {
                                        _selectedExecutorId = value;
                                      });
                                    },
                              validator: (value) {
                                if (value == null) {
                                  return 'Выберите ответственного';
                                }

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
                          : const Text('Создать'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
