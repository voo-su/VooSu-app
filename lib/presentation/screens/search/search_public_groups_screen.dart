import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/core/layout/responsive.dart';
import 'package:voosu/core/router/app_router.dart';
import 'package:voosu/domain/entities/overt_group_listing.dart';
import 'package:voosu/domain/usecases/chat/request_group_join_usecase.dart';
import 'package:voosu/domain/repositories/account_repository.dart';
import 'package:voosu/domain/usecases/chat/search_public_groups_usecase.dart';
import 'package:voosu/presentation/widgets/avatar_from_file_id.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_event.dart';
import 'package:voosu/presentation/widgets/side_navigation.dart';

class SearchPublicGroupsScreen extends StatefulWidget {
  const SearchPublicGroupsScreen({super.key});

  @override
  State<SearchPublicGroupsScreen> createState() => _SearchPublicGroupsScreenState();
}

class _SearchPublicGroupsScreenState extends State<SearchPublicGroupsScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  final List<OvertGroupListing> _items = [];
  int _page = 1;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;
  final Set<int> _joiningIds = {};

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

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
        _load(reset: true);
      }
    });
  }

  Future<void> _load({required bool reset}) async {
    if (_loading || _loadingMore) {
      return;
    }
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    } else {
      if (!_hasMore) {
        return;
      }
      setState(() => _loadingMore = true);
    }

    final page = reset ? 1 : _page + 1;
    final query = _search.text.trim();

    try {
      final useCase = di.sl<SearchPublicGroupsUseCase>();
      final r = await useCase(nameQuery: query, page: page);
      if (!mounted) {
        return;
      }
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(r.items);
        } else {
          _items.addAll(r.items);
        }
        _page = page;
        _hasMore = r.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = 'Не удалось загрузить список групп';
      });
    }
  }

  Future<void> _requestJoin(OvertGroupListing g) async {
    if (_joiningIds.contains(g.id)) {
      return;
    }
    setState(() => _joiningIds.add(g.id));
    try {
      await di.sl<RequestGroupJoinUseCase>()(g.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заявка на вступление отправлена')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is Exception ? e.toString() : 'Не удалось отправить заявку',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _joiningIds.remove(g.id));
      }
    }
  }

  void _openGroupChat(int groupId) {
    context.read<ChatBloc>().add(ChatOpenGroupById(groupId));
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
                        'Поиск групп',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _search,
                        onChanged: (_) => _scheduleSearch(),
                        decoration: InputDecoration(
                          hintText: 'Название группы',
                          isDense: true,
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 22,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
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
                        'Поиск групп',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 280,
                        child: TextField(
                          controller: _search,
                          onChanged: (_) => _scheduleSearch(),
                          decoration: InputDecoration(
                            hintText: 'Название группы',
                            isDense: true,
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 22,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: _buildBody(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (_error != null && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: () => _load(reset: true),
              child: const Text('Повторить'),
            ),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          Icon(
            Icons.groups_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 16),
          Text(
            'Ничего не найдено',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _items.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: _loadingMore
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    )
                  : TextButton(
                      onPressed: () => _load(reset: false),
                      child: const Text('Ещё'),
                    ),
            ),
          );
        }
        final g = _items[i];
        return _GroupCard(
          group: g,
          joining: _joiningIds.contains(g.id),
          onOpenChat: g.isMember ? () => _openGroupChat(g.id) : null,
          onRequestJoin:
              g.isMember ? null : () => _requestJoin(g),
        );
      },
    );
  }
}

class _GroupCard extends StatelessWidget {
  final OvertGroupListing group;
  final bool joining;
  final VoidCallback? onOpenChat;
  final VoidCallback? onRequestJoin;

  const _GroupCard({
    required this.group,
    required this.joining,
    this.onOpenChat,
    this.onRequestJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fid = group.photoId?.trim();
    final letter = group.name.isNotEmpty
        ? group.name[0].toUpperCase()
        : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: fid != null && fid.isNotEmpty
                        ? AvatarFromFileId(
                            fileId: fid,
                            letter: letter,
                            size: 52,
                            accountRepository: di.sl<AccountRepository>(),
                          )
                        : ColoredBox(
                            color: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.groups_rounded,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 28,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group.membersLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (group.description.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                group.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            if (onOpenChat != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onOpenChat,
                  icon: const Icon(Icons.chat_rounded, size: 20),
                  label: const Text('Открыть чат'),
                ),
              ),
            if (onRequestJoin != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: joining ? null : onRequestJoin,
                  icon: joining
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add_rounded, size: 20),
                  label: Text(joining ? 'Отправка…' : 'Подать заявку'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
