import 'package:flutter/material.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/domain/entities/board_column.dart';
import 'package:voosu/domain/usecases/project/get_project_columns_usecase.dart';
import 'package:voosu/domain/usecases/project/create_project_column_usecase.dart';
import 'package:voosu/domain/usecases/project/edit_project_column_usecase.dart';
import 'package:voosu/domain/usecases/project/delete_project_column_usecase.dart';
import 'package:voosu/presentation/screens/tasks/widgets/column_form_field.dart';

class ColumnsManageDialog extends StatefulWidget {
  final int projectId;
  final VoidCallback? onClosed;

  const ColumnsManageDialog({
    super.key,
    required this.projectId,
    this.onClosed,
  });

  static Future<void> show(
    BuildContext context, {
    required int projectId,
    VoidCallback? onClosed,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => ColumnsManageDialog(
        projectId: projectId,
        onClosed: onClosed,
      ),
    ).then((_) => onClosed?.call());
  }

  @override
  State<ColumnsManageDialog> createState() => _ColumnsManageDialogState();
}

class _ColumnsManageDialogState extends State<ColumnsManageDialog> {
  List<BoardColumn> _columns = [];
  bool _loading = true;
  int? _editingId;
  late TextEditingController _editTitleController;
  Color _editColor = ColumnFormField.presetColors[0];
  bool _creating = false;
  final _createTitleController = TextEditingController();
  Color _createColor = ColumnFormField.presetColors[0];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _editTitleController = TextEditingController();
    _loadColumns();
  }

  @override
  void dispose() {
    _editTitleController.dispose();
    _createTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadColumns() async {
    setState(() => _loading = true);
    try {
      final list = await di.sl<GetProjectColumnsUseCase>()(widget.projectId);
      if (mounted) {
        setState(() {
          _columns = list..sort((a, b) => a.position.compareTo(b.position));
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _startEdit(BoardColumn col) {
    setState(() {
      _editingId = col.id;
      _editTitleController.text = col.title;
      _editColor = ColumnFormField.hexToColor(col.color);
    });
  }

  void _cancelEdit() => setState(() => _editingId = null);

  Future<void> _saveEdit() async {
    final id = _editingId;
    if (id == null) {
      return;
    }

    final title = _editTitleController.text.trim();
    if (title.isEmpty) {
      _showSnack('Введите название');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await di.sl<EditProjectColumnUseCase>()(
        id,
        title: title,
        color: ColumnFormField.colorToHex(_editColor),
      );
      if (mounted) {
        setState(() {
          _editingId = null;
          _isSubmitting = false;
        });
        await _loadColumns();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnack(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _startCreate() {
    setState(() {
      _creating = true;
      _createTitleController.clear();
      _createColor = ColumnFormField.presetColors[0];
    });
  }

  void _cancelCreate() => setState(() => _creating = false);

  Future<void> _submitCreate() async {
    final title = _createTitleController.text.trim();
    if (title.isEmpty) {
      _showSnack('Введите название');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await di.sl<CreateProjectColumnUseCase>()(
        widget.projectId,
        title,
        ColumnFormField.colorToHex(_createColor),
      );
      if (mounted) {
        setState(() {
          _creating = false;
          _isSubmitting = false;
        });
        await _loadColumns();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnack(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _deleteColumn(BoardColumn col) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить колонку?'),
        content: Text(
          'Колонку «${col.title}» можно удалить только если в ней нет задач.',
        ),
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

    if (confirm != true || !mounted) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await di.sl<DeleteProjectColumnUseCase>()(col.id);
      if (mounted) {
        setState(() => _isSubmitting = false);
        await _loadColumns();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnack(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _persistOrder(List<BoardColumn> ordered) async {
    setState(() => _isSubmitting = true);
    try {
      final editUseCase = di.sl<EditProjectColumnUseCase>();
      for (var i = ordered.length - 1; i >= 0; i--) {
        await editUseCase(ordered[i].id, position: i);
      }
      if (mounted) setState(() => _isSubmitting = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnack(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.view_column, size: 24),
          SizedBox(width: 8),
          Text('Колонки'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 500),
          child: _loading
            ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
            : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_columns.isEmpty && !_creating)
                    const _ColumnsEmptyHint()
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _columns.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex--;
                          }
                          final newOrder = List<BoardColumn>.from(_columns);
                          final item = newOrder.removeAt(oldIndex);
                          newOrder.insert(newIndex, item);
                          _columns = newOrder;
                        });
                        _persistOrder(_columns);
                      },
                      itemBuilder: (context, index) {
                        final col = _columns[index];
                        final isEditing = _editingId == col.id;
                        return Column(
                          key: ValueKey(col.id),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isEditing)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ColumnFormField(
                                  controller: _editTitleController,
                                  pickedColor: _editColor,
                                  onColorChanged: (c) => setState(() => _editColor = c),
                                  onSave: _isSubmitting ? null : _saveEdit,
                                  onCancel: _cancelEdit,
                                  saveLabel: 'Сохранить',
                                ),
                              )
                            else
                              _ColumnListTile(
                                column: col,
                                index: index,
                                onEdit: () => _startEdit(col),
                                onDelete: () => _deleteColumn(col),
                              ),
                          ],
                        );
                      },
                    ),
                  if (_creating) ...[
                    const SizedBox(height: 8),
                    ColumnFormField(
                      controller: _createTitleController,
                      pickedColor: _createColor,
                      onColorChanged: (c) => setState(() => _createColor = c),
                      onSave: _isSubmitting ? null : _submitCreate,
                      onCancel: _cancelCreate,
                      saveLabel: 'Создать',
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (!_creating)
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _startCreate,
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить колонку'),
                    ),
                ],
              ),
            ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Готово'),
        ),
      ],
    );
  }
}

class _ColumnsEmptyHint extends StatelessWidget {
  const _ColumnsEmptyHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Нет колонок. Добавьте первую.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}

class _ColumnListTile extends StatelessWidget {
  final BoardColumn column;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ColumnListTile({
    required this.column,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = ColumnFormField.hexToColor(column.color);
    return ListTile(
      leading: ReorderableDragStartListener(
        index: index,
        child: Icon(Icons.drag_handle, color: Colors.grey[600]),
      ),
      title: Text(
        column.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'Позиция ${index + 1}',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
            tooltip: 'Редактировать',
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: onDelete,
            tooltip: 'Удалить',
          ),
        ],
      ),
    );
  }
}
