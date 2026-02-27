import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/data/data_sources/local/chat_notification_settings_local_data_source.dart';
import 'package:voosu/data/services/user_online_status_service.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_event.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_state.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_list_item.dart';
import 'package:voosu/presentation/widgets/loading_placeholder.dart';

class ChatListWidget extends StatefulWidget {
  final ChatState state;

  const ChatListWidget({super.key, required this.state});

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

  @override
  Widget build(BuildContext context) {
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

    final onlineService = context.read<UserOnlineStatusService>();
    final notificationSettings = context.read<ChatNotificationSettingsLocalDataSource>();

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
              itemCount: state.chats.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 60
              ),
              itemBuilder: (context, index) {
                final chat = state.chats[index];
                return ChatListItem(
                  chat: chat,
                  isSelected: chat == state.selectedChat,
                  isOnline: chat.isGroup
                    ? null
                    : (statusMap[chat.peerUserId] ?? false),
                  notificationsMuted: mutedIds.contains(chat.id),
                  onTap: () => context.read<ChatBloc>().add(ChatSelectChat(chat)),
                  onToggleNotifications: () => context.read<ChatBloc>().add(
                    ChatToggleChatNotifications(chat),
                  ),
                  onDeleteChat: () => _showDeleteChatConfirm(context, chat),
                );
              },
            );
          },
        );
      },
    );
  }

  static Future<void> _showDeleteChatConfirm(BuildContext context, Chat chat) async {
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
