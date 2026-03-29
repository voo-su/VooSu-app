import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/data/data_sources/local/chat_draft_local_data_source.dart';
import 'package:voosu/data/data_sources/local/chat_notification_settings_local_data_source.dart';
import 'package:voosu/data/services/user_online_status_service.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_event.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_state.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_content_header.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_list_item.dart';
import 'package:voosu/presentation/widgets/loading_placeholder.dart';

class ChatListWidget extends StatefulWidget {
  final ChatState state;
  final String listFilter;

  const ChatListWidget({super.key, required this.state, this.listFilter = ''});

  @override
  State<ChatListWidget> createState() => _ChatListWidgetState();
}

class _ChatListWidgetState extends State<ChatListWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatNotificationSettingsLocalDataSource>().ensureLoaded();
    });
  }

  List<Chat> _visibleChats(ChatState state) {
    final q = widget.listFilter.trim().toLowerCase();
    if (q.isEmpty) {
      return state.chats;
    }
    return state.chats.where((c) {
      final title = ChatListItem.title(c).toLowerCase();
      final username = c.userUsername.toLowerCase();
      final name = '${c.userName} ${c.userSurname}'.trim().toLowerCase();
      return title.contains(q) || username.contains(q) || name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final drafts = di.sl<ChatDraftLocalDataSource>();
    return ListenableBuilder(
      listenable: drafts,
      builder: (context, _) => _buildList(context, drafts),
    );
  }

  Widget _buildList(BuildContext context, ChatDraftLocalDataSource drafts) {
    final state = widget.state;
    if (state.isLoading && state.chats.isEmpty) {
      return const LoadingPlaceholder();
    }

    if (state.chats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Чатов пока нет',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final visible = _visibleChats(state);
    if (visible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Нет чатов по запросу',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final onlineService = context.read<UserOnlineStatusService>();
    final notificationSettings = context
        .read<ChatNotificationSettingsLocalDataSource>();

    return StreamBuilder<Set<int>>(
      stream: notificationSettings.mutedStream,
      initialData: notificationSettings.mutedChatIds,
      builder: (context, mutedSnapshot) {
        final mutedIds = mutedSnapshot.data ?? {};
        return StreamBuilder<Map<int, bool>>(
          stream: onlineService.statusStream,
          initialData: onlineService.statusMap,
          builder: (context, statusSnapshot) {
            final statusMap = statusSnapshot.data ?? {};
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: visible.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 60),
              itemBuilder: (context, index) {
                final chat = visible[index];
                return ChatListItem(
                  chat: chat,
                  draftPreview: drafts.peekForChat(chat),
                  isSelected: chat.id == state.selectedChat?.id,
                  isOnline: chat.isGroup
                      ? null
                      : (statusMap[chat.peerUserId] ?? false),
                  notificationsMuted: mutedIds.contains(chat.id),
                  onTap: () =>
                      context.read<ChatBloc>().add(ChatSelectChat(chat)),
                  onToggleNotifications: () => context.read<ChatBloc>().add(
                    ChatToggleChatNotifications(chat),
                  ),
                  onTogglePin: () =>
                      context.read<ChatBloc>().add(ChatTogglePin(chat)),
                  onShowProfile: chat.isGroup
                      ? null
                      : () => ChatContentHeader.openChatOverview(context, chat),
                  onLeaveGroup: chat.isGroup
                      ? () => _showLeaveGroupConfirm(context, chat)
                      : null,
                  onDeleteChat: () => _showDeleteChatConfirm(context, chat),
                );
              },
            );
          },
        );
      },
    );
  }

  static Future<void> _showLeaveGroupConfirm(
    BuildContext context,
    Chat chat,
  ) async {
    final title = ChatListItem.title(chat);
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
    if (confirmed == true && context.mounted) {
      context.read<ChatBloc>().add(ChatLeaveGroup(chat));
    }
  }

  static Future<void> _showDeleteChatConfirm(
    BuildContext context,
    Chat chat,
  ) async {
    final title = ChatListItem.title(chat);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить чат'),
        content: Text('Удалить чат с $title? Чат исчезнет из списка.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Удалить',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ChatBloc>().add(ChatDeleteChat(chat));
    }
  }
}
