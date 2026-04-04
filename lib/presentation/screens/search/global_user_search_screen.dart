import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/core/layout/responsive.dart';
import 'package:voosu/core/router/app_router.dart';
import 'package:voosu/domain/entities/user.dart';
import 'package:voosu/domain/usecases/search/search_users_usecase.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_event.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_list_avatar.dart';
import 'package:voosu/presentation/widgets/side_navigation.dart';

class GlobalUserSearchScreen extends StatefulWidget {
  const GlobalUserSearchScreen({super.key});

  @override
  State<GlobalUserSearchScreen> createState() => _GlobalUserSearchScreenState();
}

class _GlobalUserSearchScreenState extends State<GlobalUserSearchScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<User> _users = const [];
  String _query = '';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      if (mounted) {
        _runSearch();
      }
    });
  }

  Future<void> _runSearch() async {
    final query = _query.trim();
    if (query.isEmpty) {
      setState(() {
        _users = const [];
        _error = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final useCase = di.sl<SearchUsersUseCase>();
      final (result, _) = await useCase(query: query, page: 1, pageSize: 50);
      if (!mounted) {
        return;
      }
      setState(() {
        _users = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Ошибка загрузки пользователей';
      });
    }
  }

  void _openChat(User user) {
    context.read<ChatBloc>().add(ChatOpenWithUser(user.id));
    context.go(AppRoutes.pathForDestination(NavDestination.chat));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Breakpoints.isMobile(context)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Поиск пользователей',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _search,
                        onChanged: (v) {
                          setState(() => _query = v);
                          _scheduleSearch();
                        },
                        decoration: InputDecoration(
                          hintText: 'Имя, фамилия или логин',
                          isDense: true,
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 22,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    setState(() {
                                      _query = '';
                                      _search.clear();
                                      _users = const [];
                                      _error = null;
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Text(
                        'Поиск пользователей',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 300,
                        child: TextField(
                          controller: _search,
                          onChanged: (v) {
                            setState(() => _query = v);
                            _scheduleSearch();
                          },
                          decoration: InputDecoration(
                            hintText: 'Имя, фамилия или логин',
                            isDense: true,
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 22,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                            suffixIcon: _query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () {
                                      setState(() {
                                        _query = '';
                                        _search.clear();
                                        _users = const [];
                                        _error = null;
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildList(theme)),
        ],
      ),
    );
  }

  Widget _buildList(ThemeData theme) {
    if (_query.trim().isEmpty) {
      return Center(
        child: Text(
          'Введите запрос для поиска',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _runSearch,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }
    if (_users.isEmpty) {
      return Center(
        child: Text(
          'Пользователи не найдены',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: _users.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 68,
        color: theme.colorScheme.outline.withValues(alpha: 0.12),
      ),
      itemBuilder: (context, index) {
        final user = _users[index];
        final titleForAvatar = user.name.isNotEmpty
            ? user.name
            : (user.username.isNotEmpty ? user.username : '?');
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openChat(user),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  ChatListAvatar(
                    title: titleForAvatar,
                    isOnline: false,
                    size: 48,
                    photoId: user.photoId,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username.isNotEmpty
                              ? '@${user.username}'
                              : user.displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user.name.isNotEmpty ||
                            user.surname.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${user.name} ${user.surname}'.trim(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 22,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
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
