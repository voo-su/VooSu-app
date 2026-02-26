import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/domain/entities/user.dart';
import 'package:voosu/domain/usecases/search/search_users_usecase.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_event.dart';
import 'package:voosu/presentation/widgets/loading_placeholder.dart';

class CreateGroupChatScreen extends StatefulWidget {
  const CreateGroupChatScreen({super.key});

  @override
  State<CreateGroupChatScreen> createState() => _CreateGroupChatScreenState();
}

class _CreateGroupChatScreenState extends State<CreateGroupChatScreen> {
  final _titleController = TextEditingController();
  final _searchController = TextEditingController();
  final List<User> _selectedUsers = [];
  List<User> _searchResults = const [];
  bool _isSearching = false;
  bool _isCreating = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final usecase = di.sl<SearchUsersUseCase>();
      final (result, _) = await usecase(query: query, page: 1, pageSize: 50);
      setState(() {
        _searchResults = result
            .where((u) => !_selectedUsers.any((s) => s.id == u.id))
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _error = 'Ошибка поиска';
      });
    }
  }

  void _addUser(User user) {
    if (_selectedUsers.any((u) => u.id == user.id)) return;
    setState(() {
      _selectedUsers.add(user);
      _searchResults = _searchResults.where((u) => u.id != user.id).toList();
    });
  }

  void _removeUser(User user) {
    setState(() {
      _selectedUsers.removeWhere((u) => u.id == user.id);
    });
  }

  void _create() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Введите название группы');
      return;
    }

    if (_selectedUsers.isEmpty) {
      setState(() => _error = 'Добавьте хотя бы одного участника');
      return;
    }

    setState(() {
      _isCreating = true;
      _error = null;
    });
    context.read<ChatBloc>().add(
      ChatCreateGroupRequested(title, _selectedUsers.map((u) => u.id).toList()),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый групповой чат'),
        actions: [
          TextButton(
            onPressed: _isCreating || _selectedUsers.isEmpty ? null : _create,
            child: const Text('Создать'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название группы',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Участники (${_selectedUsers.length})',
              style: theme.textTheme.titleSmall,
            ),
          ),
          if (_selectedUsers.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                itemCount: _selectedUsers.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final user = _selectedUsers[index];
                  return Chip(
                    label: Text(
                      user.username.isNotEmpty
                          ? user.username
                          : '${user.name} ${user.surname}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onDeleted: () => _removeUser(user),
                  );
                },
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Добавить участника - поиск по имени или логину',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _search(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          Expanded(
            child: _isSearching
                ? const LoadingPlaceholder()
                : _searchResults.isEmpty
                ? const Center(
                    child: Text(
                      'Введите запрос для поиска пользователей',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(
                          user.username.isNotEmpty
                              ? user.username
                              : '${user.name} ${user.surname}',
                        ),
                        subtitle: user.username.isNotEmpty
                            ? Text('${user.name} ${user.surname}')
                            : null,
                        onTap: () => _addUser(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
