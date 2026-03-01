import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/date_formatter.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/core/util.dart';
import 'package:voosu/domain/entities/project_activity.dart';
import 'package:voosu/domain/usecases/project/get_project_history_usecase.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_event.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_state.dart';

class ProjectHistoryDialog extends StatefulWidget {
  final int projectId;

  const ProjectHistoryDialog({super.key, required this.projectId});

  static Future<void> show(BuildContext context, {required int projectId}) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<ProjectBloc>(),
        child: ProjectHistoryDialog(projectId: projectId),
      ),
    );
  }

  @override
  State<ProjectHistoryDialog> createState() => _ProjectHistoryDialogState();
}

class _ProjectHistoryDialogState extends State<ProjectHistoryDialog> {
  List<ProjectActivity> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    context.read<ProjectBloc>().add(
      ProjectMembersLoadRequested(widget.projectId),
    );
    _load();
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }

    setState(() => _loading = true);
    try {
      final list = await di.sl<GetProjectHistoryUseCase>()(widget.projectId);
      if (mounted) {
        setState(() => _items = list);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _items = []);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.history, size: 24),
          SizedBox(width: 8),
          Text('История'),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 450),
          child: _loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _items.isEmpty
              ? Center(
                  child: Text(
                    'Нет записей в истории',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  ),
                )
              : BlocBuilder<ProjectBloc, ProjectState>(
                  buildWhen: (a, b) => a.members != b.members,
                  builder: (context, state) {
                    final members = state.members.map((m) => m.user).toList();
                    return RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(right: 8),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final a = _items[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.actionLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                      if (a.payload.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          a.payload,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey[700],
                                              ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        '${DateFormatter.formatDate(a.createdAt)} - ${userDisplayNameForId(members, a.userId)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}
