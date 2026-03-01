import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/domain/entities/project.dart';
import 'package:voosu/domain/entities/user.dart';
import 'package:voosu/domain/usecases/search/search_users_usecase.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_event.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_state.dart';

class ProjectMembersDialog extends StatefulWidget {
  final Project project;

  const ProjectMembersDialog({super.key, required this.project});

  static Future<void> show(BuildContext context, {required Project project}) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<ProjectBloc>(),
        child: ProjectMembersDialog(project: project),
      ),
    );
  }

  @override
  State<ProjectMembersDialog> createState() => _ProjectMembersDialogState();
}

class _ProjectMembersDialogState extends State<ProjectMembersDialog> {
  bool _showAddMode = false;
  final _searchController = TextEditingController();
  List<User> _searchUsers = const [];
  final Set<int> _selectedIds = {};
  String _query = '';
  bool _searchLoading = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectBloc>().add(ProjectSelected(widget.project));
      context.read<ProjectBloc>().add(
        ProjectMembersLoadRequested(widget.project.id),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<int> get _existingMemberIds {
    final state = context.read<ProjectBloc>().state;
    if (state.selectedProject?.id != widget.project.id) {
      return [];
    }
    return state.members
        .map((m) => m.user.id)
        .whereType<int>()
        .toList();
  }

  bool get _isCurrentUserAdmin {
    final state = context.read<ProjectBloc>().state;
    final p = state.selectedProject?.id == widget.project.id
        ? state.selectedProject
        : widget.project;

    return p?.isCurrentUserAdmin ?? false;
  }

  void _switchToAddMode() {
    setState(() {
      _showAddMode = true;
      _searchController.clear();
      _query = '';
      _searchUsers = const [];
      _selectedIds.clear();
      _searchError = null;
    });
  }

  void _switchToListMode() {
    setState(() {
      _showAddMode = false;
    });
  }

  Future<void> _search() async {
    final query = _query.trim();
    if (query.isEmpty) {
      setState(() {
        _searchUsers = const [];
        _searchError = null;
      });
      return;
    }
    setState(() {
      _searchLoading = true;
      _searchError = null;
    });
    try {
      final usecase = di.sl<SearchUsersUseCase>();
      final (result, _) = await usecase(query: query, page: 1, pageSize: 50);
      if (mounted) {
        setState(() {
          _searchUsers = result;
          _searchLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchLoading = false;
          _searchError = 'Ошибка загрузки пользователей';
        });
      }
    }
  }

  void _toggleUser(User user) {
    final intId = user.id;
    if (intId == 0 || _existingMemberIds.contains(intId)) {
      return;
    }

    setState(() {
      if (_selectedIds.contains(user.id)) {
        _selectedIds.remove(user.id);
      } else {
        _selectedIds.add(user.id);
      }
    });
  }

  void _confirmAdd() {
    final ids = _selectedIds
        .map((id) => id)
        .whereType<int>()
        .toList();
    if (ids.isEmpty) {
      return;
    }
    context.read<ProjectBloc>().add(
      ProjectAddMembersRequested(widget.project.id, ids),
    );
    context.read<ProjectBloc>().add(
      ProjectMembersLoadRequested(widget.project.id),
    );
    _switchToListMode();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(_showAddMode ? Icons.person_add : Icons.people, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _showAddMode
                  ? 'Добавить участников'
                  : 'Участники: ${widget.project.name}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: _showAddMode ? _buildAddContent() : _buildListContent(),
        ),
      ),
      actions: _showAddMode ? _buildAddActions() : _buildListActions(),
    );
  }

  Widget _buildListContent() {
    return BlocBuilder<ProjectBloc, ProjectState>(
      buildWhen: (a, b) =>
          a.members != b.members || a.isMembersLoading != b.isMembersLoading,
      builder: (context, state) {
        if (state.isMembersLoading && state.members.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (state.members.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Участников пока нет',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (_isCurrentUserAdmin)
                  FilledButton.icon(
                    onPressed: _switchToAddMode,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Добавить участников'),
                  ),
              ],
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          itemCount: state.members.length,
          itemBuilder: (context, index) {
            final item = state.members[index];
            final user = item.user;
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 18,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      user.username,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  if (item.isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Chip(
                        label: const Text(
                          'Админ',
                          style: TextStyle(fontSize: 11),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                '${user.name} ${user.surname}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              trailing: _isCurrentUserAdmin
                  ? IconButton(
                      icon: const Icon(Icons.person_remove, size: 20),
                      tooltip: 'Удалить из проекта',
                      onPressed: () {
                        final uid = user.id;
                        if (uid != 0) {
                          context.read<ProjectBloc>().add(
                            ProjectRemoveMemberRequested(
                              widget.project.id,
                              uid,
                            ),
                          );
                          context.read<ProjectBloc>().add(
                            ProjectMembersLoadRequested(widget.project.id),
                          );
                        }
                      },
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildAddContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Имя, фамилия или логин',
            prefixIcon: const Icon(Icons.search, size: 20),
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _query = '';
                        _searchController.clear();
                        _searchUsers = const [];
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() => _query = value);
            _search();
          },
        ),
        const SizedBox(height: 12),
        Flexible(
          child: _searchLoading
              ? const Center(child: CircularProgressIndicator())
              : _searchError != null
              ? Center(
                  child: Text(
                    _searchError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                )
              : _searchUsers.isEmpty
              ? Center(
                  child: Text(
                    _query.trim().isEmpty
                        ? 'Введите запрос для поиска'
                        : 'Никого не найдено',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchUsers.length,
                  itemBuilder: (context, index) {
                    final user = _searchUsers[index];
                    final intId = user.id;
                    final isExisting = intId != 0 && _existingMemberIds.contains(intId);
                    final isSelected = _selectedIds.contains(user.id);
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 18,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      title: Text(
                        user.username,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        '${user.name} ${user.surname}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: isExisting
                          ? const Chip(
                              label: Text(
                                'В проекте',
                                style: TextStyle(fontSize: 11),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                            )
                          : Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleUser(user),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                      onTap: isExisting ? null : () => _toggleUser(user),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<Widget> _buildListActions() {
    return [
      if (_isCurrentUserAdmin)
        TextButton.icon(
          onPressed: _switchToAddMode,
          icon: const Icon(Icons.person_add, size: 18),
          label: const Text('Добавить участников'),
        ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Закрыть'),
      ),
    ];
  }

  List<Widget> _buildAddActions() {
    return [
      TextButton(onPressed: _switchToListMode, child: const Text('Назад')),
      if (_selectedIds.isNotEmpty)
        FilledButton(
          onPressed: _confirmAdd,
          child: Text('Добавить (${_selectedIds.length})'),
        ),
    ];
  }
}
