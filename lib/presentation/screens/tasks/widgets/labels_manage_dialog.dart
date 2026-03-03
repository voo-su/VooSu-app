import 'package:flutter/material.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/domain/entities/project_label.dart';
import 'package:voosu/domain/usecases/project/get_project_labels_usecase.dart';
import 'package:voosu/domain/usecases/project/create_project_label_usecase.dart';
import 'package:voosu/domain/usecases/project/update_project_label_usecase.dart';
import 'package:voosu/domain/usecases/project/delete_project_label_usecase.dart';
import 'package:voosu/presentation/screens/tasks/widgets/column_form_field.dart';

class LabelsManageDialog extends StatefulWidget {
  final int projectId;
  final VoidCallback? onClosed;

  const LabelsManageDialog({
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
      builder: (ctx) => LabelsManageDialog(
        projectId: projectId,
        onClosed: onClosed,
      ),
    ).then((_) => onClosed?.call());
  }

  @override
  State<LabelsManageDialog> createState() => _LabelsManageDialogState();
}

class _LabelsManageDialogState extends State<LabelsManageDialog> {
  List<ProjectLabel> _labels = [];
  bool _loading = true;
  int? _editingId;
  late TextEditingController _editNameController;
  Color _editColor = ColumnFormField.presetColors[0];
  bool _creating = false;
  final _createNameController = TextEditingController();
  Color _createColor = ColumnFormField.presetColors[0];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _editNameController = TextEditingController();
    _loadLabels();
  }

  @override
  void dispose() {
    _editNameController.dispose();
    _createNameController.dispose();
    super.dispose();
  }

  Future<void> _loadLabels() async {
    setState(() => _loading = true);
    try {
      final list = await di.sl<GetProjectLabelsUseCase>()(widget.projectId);
      if (mounted) {
        setState(() {
          _labels = list..sort((a, b) => a.name.compareTo(b.name));
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _startEdit(ProjectLabel label) {
    setState(() {
      _editingId = label.id;
      _editNameController.text = label.name;
      _editColor = ColumnFormField.hexToColor(label.color);
    });
  }

  void _cancelEdit() => setState(() => _editingId = null);

  Future<void> _saveEdit() async {
    final id = _editingId;
    if (id == null) {
      return;
    }

    final name = _editNameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Введите название');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await di.sl<UpdateProjectLabelUseCase>()(
        id,
        name: name,
        color: ColumnFormField.colorToHex(_editColor),
      );
      if (mounted) {
        setState(() {
          _editingId = null;
          _isSubmitting = false;
        });
        await _loadLabels();
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
      _createNameController.clear();
      _createColor = ColumnFormField.presetColors[0];
    });
  }

  void _cancelCreate() => setState(() => _creating = false);

  Future<void> _submitCreate() async {
    final name = _createNameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Введите название');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await di.sl<CreateProjectLabelUseCase>()(
        widget.projectId,
        name,
        ColumnFormField.colorToHex(_createColor),
      );
      if (mounted) {
        setState(() {
          _creating = false;
          _isSubmitting = false;
        });
        await _loadLabels();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnack(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _deleteLabel(ProjectLabel label) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить метку?'),
        content: Text('Метка "${label.name}" будет удалена из проекта. Она будет снята со всех задач.'),
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
      await di.sl<DeleteProjectLabelUseCase>()(label.id);
      if (mounted) {
        setState(() => _isSubmitting = false);
        await _loadLabels();
      }
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
          Icon(Icons.label_outline, size: 24),
          SizedBox(width: 8),
          Text('Метки проекта'),
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
                  if (_labels.isEmpty && !_creating)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Нет меток. Добавьте первую.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ..._labels.map((label) {
                      final isEditing = _editingId == label.id;
                      return Column(
                        key: ValueKey(label.id),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isEditing)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ColumnFormField(
                                controller: _editNameController,
                                pickedColor: _editColor,
                                onColorChanged: (c) => setState(() => _editColor = c),
                                onSave: _isSubmitting ? null : _saveEdit,
                                onCancel: _cancelEdit,
                                saveLabel: 'Сохранить',
                              ),
                            )
                          else
                            _LabelListTile(
                              label: label,
                              onEdit: () => _startEdit(label),
                              onDelete: () => _deleteLabel(label),
                            ),
                        ],
                      );
                    }),
                  if (_creating) ...[
                    const SizedBox(height: 8),
                    ColumnFormField(
                      controller: _createNameController,
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
                      label: const Text('Добавить метку'),
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

class _LabelListTile extends StatelessWidget {
  final ProjectLabel label;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LabelListTile({
    required this.label,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = ColumnFormField.hexToColor(label.color);
    return ListTile(
      leading: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
      ),
      title: Text(
        label.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
