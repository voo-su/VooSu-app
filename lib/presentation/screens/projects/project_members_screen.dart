import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/domain/entities/project.dart';
import 'package:voosu/domain/entities/user.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_event.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_state.dart';
import 'package:voosu/presentation/screens/projects/project_add_members_screen.dart';
import 'package:voosu/presentation/widgets/loading_placeholder.dart';

class ProjectMembersScreen extends StatefulWidget {
  final Project project;

  const ProjectMembersScreen({super.key, required this.project});

  @override
  State<ProjectMembersScreen> createState() => _ProjectMembersScreenState();
}

class _ProjectMembersScreenState extends State<ProjectMembersScreen> {
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

  Future<void> _openAddMembers(Project project) async {
    final bloc = context.read<ProjectBloc>();
    final state = bloc.state;
    final existingIds = state.selectedProject?.id == project.id
    ? state.members
      .map((m) => m.user.id)
      .whereType<int>()
      .toList()
    : <int>[];

    final result = await Navigator.of(context).push<List<int>>(
      MaterialPageRoute<List<int>>(
        builder: (_) => ProjectAddMembersScreen(
          projectId: project.id,
          existingMemberIds: existingIds,
        ),
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      context.read<ProjectBloc>().add(
        ProjectAddMembersRequested(project.id, result),
      );
      context.read<ProjectBloc>().add(ProjectMembersLoadRequested(project.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        final project = state.selectedProject?.id == widget.project.id
            ? state.selectedProject!
            : widget.project;
        final canAddMembers = project.isCurrentUserAdmin;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text('Участники: ${widget.project.name}'),
            actions: [
              if (canAddMembers)
                IconButton(
                  icon: const Icon(Icons.person_add),
                  tooltip: 'Добавить участников',
                  onPressed: () => _openAddMembers(widget.project),
                ),
            ],
          ),
          body: _buildMembersList(state),
        );
      },
    );
  }

  Widget _buildMembersList(ProjectState state) {
    if (state.isMembersLoading && state.members.isEmpty) {
      return const LoadingPlaceholder();
    }
    if (state.members.isEmpty) {
      final project = state.selectedProject?.id == widget.project.id
          ? state.selectedProject!
          : widget.project;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Участников пока нет',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (project.isCurrentUserAdmin) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => _openAddMembers(widget.project),
                icon: const Icon(Icons.person_add),
                label: const Text('Добавить участников'),
              ),
            ],
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: state.members.length,
      itemBuilder: (context, index) {
        final item = state.members[index];
        return _MemberTile(user: item.user, isAdmin: item.isAdmin);
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  final User user;
  final bool isAdmin;

  const _MemberTile({required this.user, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
      ),
      title: Row(
        children: [
          Expanded(child: Text(user.username)),
          if (isAdmin)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Chip(
                label: Text('Админ', style: TextStyle(fontSize: 11)),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      subtitle: Text('${user.name} ${user.surname}'),
    );
  }
}
