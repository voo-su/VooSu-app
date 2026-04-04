import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/core/layout/responsive.dart';
import 'package:voosu/core/router/app_router.dart';
import 'package:voosu/domain/entities/contact_list_item.dart';
import 'package:voosu/domain/entities/contact_user_profile.dart';
import 'package:voosu/domain/usecases/contact/get_contact_user_usecase.dart';
import 'package:voosu/domain/repositories/account_repository.dart';
import 'package:voosu/domain/usecases/contact/get_contacts_usecase.dart';
import 'package:voosu/presentation/widgets/avatar_from_file_id.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_event.dart';
import 'package:voosu/presentation/widgets/side_navigation.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _search = TextEditingController();
  List<ContactListItem> _all = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await di.sl<GetContactsUseCase>()();
      if (mounted) {
        setState(() {
          _all = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Не удалось загрузить контакты';
        });
      }
    }
  }

  List<ContactListItem> get _filtered =>
      _all.where((e) => e.matchesQuery(_search.text)).toList();

  void _openChat(int userId) {
    context.read<ChatBloc>().add(ChatOpenWithUser(userId));
    context.go(AppRoutes.pathForDestination(NavDestination.chat));
  }

  Future<void> _showProfile(int userId) async {
    final isMobile = Breakpoints.isMobile(context);
    if (isMobile) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) => _ContactProfileSheet(
          userId: userId,
          onWrite: () {
            Navigator.of(ctx).pop();
            _openChat(userId);
          },
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
            child: _ContactProfileSheet(
              userId: userId,
              onWrite: () {
                Navigator.of(ctx).pop();
                _openChat(userId);
              },
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

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
                        'Контакты',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          hintText: 'Поиск',
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
                        'Контакты',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 220,
                        child: TextField(
                          controller: _search,
                          decoration: InputDecoration(
                            hintText: 'Поиск',
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
              onRefresh: _load,
              child: _buildBody(context, theme, filtered),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    List<ContactListItem> filtered,
  ) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: _load,
              child: const Text('Повторить'),
            ),
          ),
        ],
      );
    }
    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 16),
          Text(
            _all.isEmpty
                ? 'Список контактов пуст'
                : 'Никого не найдено по запросу',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, i) {
        final item = filtered[i];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showProfile(item.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  _ContactAvatar(
                    photoId: item.photoId,
                    username: item.username,
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@${item.username}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.name.isNotEmpty || item.surname.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${item.name} ${item.surname}'.trim(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Написать',
                    onPressed: () => _openChat(item.id),
                    icon: const Icon(Icons.send_rounded),
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

class _ContactAvatar extends StatelessWidget {
  final String? photoId;
  final String username;
  final double radius;

  const _ContactAvatar({
    required this.photoId,
    required this.username,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String initial = username.isNotEmpty
        ? username.characters.first.toUpperCase()
        : '?';
    final id = photoId?.trim();
    if (id != null && id.isNotEmpty) {
      return AvatarFromFileId(
        fileId: id,
        letter: initial,
        size: radius * 2,
        accountRepository: di.sl<AccountRepository>(),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.85,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _ContactProfileSheet extends StatefulWidget {
  final int userId;
  final VoidCallback onWrite;

  const _ContactProfileSheet({
    required this.userId,
    required this.onWrite,
  });

  @override
  State<_ContactProfileSheet> createState() => _ContactProfileSheetState();
}

class _ContactProfileSheetState extends State<_ContactProfileSheet> {
  ContactUserProfile? _profile;
  bool _loading = true;
  String? _error;

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
      final p = await di.sl<GetContactUserUseCase>()(widget.userId);
      if (mounted) {
        setState(() {
          _profile = p;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Не удалось загрузить профиль';
        });
      }
    }
  }

  String _genderLabel(int g) {
    switch (g) {
      case 1:
        return 'Мужской';
      case 2:
        return 'Женский';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: _loading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _load, child: const Text('Повторить')),
                ],
              )
            : _profile == null
            ? const SizedBox.shrink()
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: _ContactAvatar(
                        photoId: _profile!.photoId,
                        username: _profile!.username,
                        radius: 50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _profile!.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _labelValue(theme, 'Логин', '@${_profile!.username}'),
                    if (_profile!.name.trim().isNotEmpty)
                      _labelValue(theme, 'Имя', _profile!.name),
                    if (_profile!.surname.trim().isNotEmpty)
                      _labelValue(theme, 'Фамилия', _profile!.surname),
                    if (_genderLabel(_profile!.gender).isNotEmpty)
                      _labelValue(
                        theme,
                        'Пол',
                        _genderLabel(_profile!.gender),
                      ),
                    if (_profile!.about.trim().isNotEmpty)
                      _labelValue(theme, 'О себе', _profile!.about),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: widget.onWrite,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Написать'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _labelValue(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
