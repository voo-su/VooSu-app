import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/core/util.dart';
import 'package:voosu/domain/repositories/account_repository.dart';
import 'package:voosu/presentation/widgets/avatar_from_file_id.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/domain/entities/group_info.dart';
import 'package:voosu/presentation/widgets/loading_placeholder.dart';
import 'package:voosu/domain/entities/user.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';
import 'package:voosu/domain/usecases/search/search_users_usecase.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_event.dart';

class GroupInfoScreen extends StatefulWidget {
  final int groupId;
  final String groupTitle;
  final int? currentUserId;
  final bool isModal;

  const GroupInfoScreen({
    super.key,
    required this.groupId,
    required this.groupTitle,
    this.currentUserId,
    this.isModal = false,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final ChatRepository _repo = di.sl<ChatRepository>();
  GroupInfo? _info;
  bool _loading = true;
  String? _error;
  bool _addingMember = false;
  bool _leavingGroup = false;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await _repo.getGroupInfo(widget.groupId);
      if (mounted) {
        setState(() {
          _info = info;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Не удалось загрузить информацию о группе';
        });
      }
    }
  }

  bool get _isCurrentUserAdmin {
    if (widget.currentUserId == null || _info == null) {
      return false;
    }

    final m = _info!.memberByUserId[widget.currentUserId!];
    return m?.isAdmin ?? false;
  }

  Future<void> _addMembers(List<int> userIds) async {
    if (userIds.isEmpty) {
      return;
    }

    setState(() {
      _addingMember = true;
      _actionError = null;
    });
    try {
      await _repo.addGroupMembers(widget.groupId, userIds);
      if (mounted) {
        context.read<ChatBloc>().add(const ChatLoadChats());
        await _load();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _actionError = 'Ошибка добавления';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _addingMember = false);
      }
    }
  }

  Future<void> _setRole(int userId, int role) async {
    setState(() => _actionError = null);
    try {
      await _repo.setGroupMemberRole(widget.groupId, userId, role);
      if (mounted) {
        await _load();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionError = 'Ошибка изменения роли');
      }
    }
  }

  Future<void> _removeMember(int userId) async {
    setState(() => _actionError = null);
    try {
      await _repo.removeGroupMembers(widget.groupId, [userId]);
      if (mounted) {
        context.read<ChatBloc>().add(const ChatLoadChats());
        await _load();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionError = 'Ошибка удаления участника');
      }
    }
  }

  Future<void> _uploadGroupPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final path = result.files.single.path;
    if (path == null) {
      return;
    }

    final bytes = await File(path).readAsBytes();
    final filename = result.files.single.name;
    if (filename.isEmpty) {
      return;
    }

    setState(() => _actionError = null);
    try {
      final fileId = await _repo.uploadFile(
        filename: filename,
        chunkStream: Stream.fromIterable([bytes]),
        totalBytes: bytes.length,
      );
      await _repo.uploadGroupPhoto(widget.groupId, fileId);
      if (mounted) {
        context.read<ChatBloc>().add(const ChatLoadChats());
        await _load();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionError = 'Не удалось загрузить фото');
      }
    }
  }

  Future<void> _confirmLeaveGroup() async {
    final title = _info?.title ?? widget.groupTitle;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Покинуть группу'),
        content: Text('Выйти из группы «$title»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Выйти',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _actionError = null;
      _leavingGroup = true;
    });
    try {
      await _repo.leaveGroup(widget.groupId);
    } on Failure catch (e) {
      if (mounted) {
        setState(() {
          _actionError = e.message;
          _leavingGroup = false;
        });
      }
      return;
    } catch (_) {
      if (mounted) {
        setState(() {
          _actionError = 'Не удалось выйти из группы';
          _leavingGroup = false;
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _leavingGroup = false);
    context.read<ChatBloc>().add(ChatGroupLeftApplied(widget.groupId));
    Navigator.of(context).pop();
  }

  void _openAddMember() async {
    final added = await Navigator.of(context).push<List<int>>(
      MaterialPageRoute(
        builder: (context) => _AddGroupMemberScreen(
          groupId: widget.groupId,
          existingUserIds: _info?.members.map((m) => m.userId).toList() ?? [],
        ),
      ),
    );

    if (added != null && added.isNotEmpty && mounted) {
      await _addMembers(added);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Информация о группе'),
        automaticallyImplyLeading: !widget.isModal,
        actions: [
          if (widget.isModal)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
      body: _loading
          ? const LoadingPlaceholder()
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _load,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            )
          : _info == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _isCurrentUserAdmin ? _uploadGroupPhoto : null,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _info!.avatarFileId != null && _info!.avatarFileId! != 0
                            ? AvatarFromFileId(
                              fileId: _info!.avatarFileId,
                              letter: _info!.title.isNotEmpty
                                ? _info!.title[0].toUpperCase()
                                : '?',
                              size: 96,
                              accountRepository: di.sl<AccountRepository>(),
                            )
                            : CircleAvatar(
                              radius: 48,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                _info!.title.isNotEmpty
                                  ? _info!.title[0].toUpperCase()
                                  : '?',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          if (_isCurrentUserAdmin)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: theme.colorScheme.primary,
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _info!.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    participantsSubtitle(
                      _info!.memberCount,
                      emptyLabel: 'Нет участников',
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_actionError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _actionError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  if (_isCurrentUserAdmin) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _addingMember ? null : _openAddMember,
                      icon: _addingMember
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_add_rounded),
                      label: const Text('Добавить участника'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Участники',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._info!.members.map(
                    (m) => _MemberTile(
                      member: m,
                      user: _info!.userById[m.userId],
                      currentUserId: widget.currentUserId,
                      isAdmin: _isCurrentUserAdmin,
                      onSetRole: _setRole,
                      onRemoveMember: _isCurrentUserAdmin ? _removeMember : null,
                    ),
                  ),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: _leavingGroup ? null : _confirmLeaveGroup,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Покинуть группу'),
                  ),
                ],
              ),
            ),
    );
  }
}

const int _kRemoveMemberAction = 2;

class _MemberTile extends StatelessWidget {
  final GroupMemberInfo member;
  final User? user;
  final int? currentUserId;
  final bool isAdmin;
  final Future<void> Function(int userId, int role) onSetRole;
  final Future<void> Function(int userId)? onRemoveMember;

  const _MemberTile({
    required this.member,
    required this.user,
    required this.currentUserId,
    required this.isAdmin,
    required this.onSetRole,
    this.onRemoveMember,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = currentUserId == member.userId;
    final displayName = user != null
        ? (user!.username.isNotEmpty
              ? user!.username
              : '${user!.name} ${user!.surname}'.trim())
        : 'ID ${member.userId}';

    return ListTile(
      leading: CircleAvatar(
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (member.isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Админ',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      subtitle: isMe ? const Text('Вы') : null,
      trailing: isAdmin && !isMe
          ? PopupMenuButton<int>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == _kRemoveMemberAction) {
                  await onRemoveMember?.call(member.userId);
                } else {
                  await onSetRole(member.userId, value);
                }
              },
              itemBuilder: (context) => [
                if (member.isAdmin)
                  const PopupMenuItem(
                    value: 0,
                    child: Text('Убрать права админа'),
                  )
                else
                  const PopupMenuItem(value: 1, child: Text('Сделать админом')),
                if (onRemoveMember != null)
                  const PopupMenuItem(
                    value: _kRemoveMemberAction,
                    child: Text('Исключить из группы'),
                  ),
              ],
            )
          : null,
    );
  }
}

class _AddGroupMemberScreen extends StatefulWidget {
  final int groupId;
  final List<int> existingUserIds;

  const _AddGroupMemberScreen({
    required this.groupId,
    required this.existingUserIds,
  });

  @override
  State<_AddGroupMemberScreen> createState() => _AddGroupMemberScreenState();
}

class _AddGroupMemberScreenState extends State<_AddGroupMemberScreen> {
  final _searchController = TextEditingController();
  final SearchUsersUseCase _searchUseCase = di.sl<SearchUsersUseCase>();
  List<User> _users = [];
  bool _searching = false;
  final Set<int> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _users = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final (result, _) = await _searchUseCase(
        query: query.trim(),
        page: 1,
        pageSize: 50,
      );
      if (mounted) {
        setState(() {
          _users = result
              .where((u) => !widget.existingUserIds.contains(u.id))
              .toList();
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _toggle(User user) {
    setState(() {
      if (_selectedIds.contains(user.id)) {
        _selectedIds.remove(user.id);
      } else {
        _selectedIds.add(user.id);
      }
    });
  }

  void _submit() {
    Navigator.of(context).pop(_selectedIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить участника'),
        actions: [
          if (_selectedIds.isNotEmpty)
            TextButton(
              onPressed: _submit,
              child: Text('Добавить (${_selectedIds.length})'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по имени или логину',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: _searching
                ? const LoadingPlaceholder()
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final selected = _selectedIds.contains(user.id);
                      final name = user.username.isNotEmpty
                          ? user.username
                          : '${user.name} ${user.surname}'.trim();
                      return CheckboxListTile(
                        value: selected,
                        onChanged: (_) => _toggle(user),
                        title: Text(name),
                        subtitle: user.username.isNotEmpty
                            ? Text('${user.name} ${user.surname}')
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
