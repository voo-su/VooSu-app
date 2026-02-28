import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/domain/entities/project.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_event.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_state.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectBloc>().add(ProjectSelected(widget.project));
    });
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
    return BlocBuilder<ProjectBloc, ProjectState>(
      buildWhen: (a, b) => a.selectedProject != b.selectedProject,
      builder: (context, projectState) {
        final project =
            projectState.selectedProject?.id == widget.project.id
            ? projectState.selectedProject!
            : widget.project;
        final theme = Theme.of(context);
        final muted = theme.colorScheme.onSurfaceVariant;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              project.name,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (project.isCurrentUserAdmin)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Переименовать проект',
                  onPressed: _openEditName,
                ),
            ],
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 56,
                    color: theme.colorScheme.primary.withValues(alpha: 0.85),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    project.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Проект',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
