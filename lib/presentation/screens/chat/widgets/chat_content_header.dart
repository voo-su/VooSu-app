import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/util.dart';
import 'package:voosu/data/data_sources/local/chat_notification_settings_local_data_source.dart';
import 'package:voosu/data/services/user_online_status_service.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_event.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_state.dart';
import 'package:voosu/presentation/screens/chat/group_info_screen.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_delete_scope_dialog.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_list_avatar.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_list_item.dart';
import 'package:voosu/presentation/screens/chat/widgets/typing_dots_indicator.dart';
import 'package:voosu/core/layout/responsive.dart';

class ChatContentHeader extends StatelessWidget {
  final Chat? selectedChat;
  final bool showBackButton;
  final ChatState chatState;
  final int? currentUserId;

  const ChatContentHeader({
    super.key,
    required this.selectedChat,
    required this.chatState,
    this.currentUserId,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (selectedChat == null && !chatState.isSelectionMode) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        bottom: 10,
        left: showBackButton ? 4 : 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: chatState.isSelectionMode
          ? _buildSelectionHeader(context, theme)
          : _buildChatHeader(context, theme),
    );
  }

  Widget _buildSelectionHeader(BuildContext context, ThemeData theme) {
    final count = chatState.selectedMessageIds.length;
    final currentUserId = this.currentUserId;
    final myMessageIds = currentUserId != null
        ? chatState.messages
              .where((m) => m.senderId == currentUserId)
              .map((m) => m.id)
              .toSet()
        : <int>{};
    final allMySelected =
        myMessageIds.isNotEmpty &&
        myMessageIds.every((id) => chatState.selectedMessageIds.contains(id));
    final someMySelected = myMessageIds.any(
      (id) => chatState.selectedMessageIds.contains(id),
    );

    return Row(
      children: [
        if (showBackButton) const SizedBox(width: 48),
        if (myMessageIds.isNotEmpty)
          Checkbox(
            value: allMySelected ? true : (someMySelected ? null : false),
            tristate: true,
            onChanged: (value) {
              if (value == true) {
                context.read<ChatBloc>().add(const ChatSelectAllMyMessages());
              } else {
                context.read<ChatBloc>().add(const ChatClearSelection());
              }
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        Expanded(
          child: Text(
            'Выбрано: $count',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
        TextButton(
          onPressed: () =>
              context.read<ChatBloc>().add(const ChatClearSelection()),
          child: const Text('Отмена'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () async {
            final forEveryone = await showDeleteScopeDialog(context);
            if (context.mounted && forEveryone != null) {
              context.read<ChatBloc>().add(
                ChatDeleteSelectedMessages(forEveryone: forEveryone),
              );
            }
          },
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Удалить'),
        ),
      ],
    );
  }

  Widget _buildChatHeader(BuildContext context, ThemeData theme) {
    final chat = selectedChat!;
    final onlineService = context.read<UserOnlineStatusService>();
    final notificationSettings = context
        .read<ChatNotificationSettingsLocalDataSource>();
    final isOnline = chat.isGroup
        ? null
        : (onlineService.isOnline(chat.peerUserId) ?? false);
    final isTyping =
        chatState.typingUserId != null &&
        chatState.typingUserId == chat.peerUserId;
    final title = ChatListItem.title(chat);

    final subtitle = chat.isGroup
        ? participantsSubtitle(chat.memberCount)
        : (isOnline == true ? 'в сети' : 'не в сети');
    final subtitleColor = isOnline == true
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
    final typingColor = theme.colorScheme.primary;

    return StreamBuilder<Set<int>>(
      stream: notificationSettings.mutedStream,
      initialData: notificationSettings.mutedChatIds,
      builder: (context, snapshot) {
        final mutedIds = snapshot.data ?? {};
        final notificationsMuted = mutedIds.contains(chat.id);

        return Row(
          children: [
            if (showBackButton)
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.read<ChatBloc>().add(const ChatBackToList()),
              ),
            Expanded(
              child: InkWell(
                onTap: () => _onHeaderTap(context, chat),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      ChatListAvatar(
                        title: title,
                        isOnline: isOnline,
                        size: 40,
                        avatarFileId: chat.avatarFileId,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isTyping)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'печатает',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: typingColor,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  TypingDotsIndicator(
                                    color: typingColor,
                                    dotSize: 4,
                                    spacing: 4,
                                  ),
                                ],
                              )
                            else
                              Text(
                                subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: subtitleColor,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 22),
              tooltip: '',
              onSelected: (value) {
                if (value == 'notifications') {
                  context.read<ChatBloc>().add(ChatToggleChatNotifications(chat));
                } else if (value == 'clear_history') {
                  _showClearHistoryConfirm(context);
                } else if (value == 'delete_chat') {
                  _showDeleteChatConfirm(context, chat);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'notifications',
                  child: Row(
                    children: [
                      Icon(
                        notificationsMuted
                          ? Icons.notifications_outlined
                          : Icons.notifications_off_outlined,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        notificationsMuted
                          ? 'Включить уведомления'
                          : 'Отключить уведомления',
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'clear_history',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Очистить историю'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete_chat',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Удалить чат',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showClearHistoryConfirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: const Text('Очистить историю?'),
          content: Text(
            'Все сообщения в этом чате исчезнут только у вас. У собеседника история сохранится.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Очистить'),
            ),
          ],
        );
      },
    );

    if (context.mounted && confirmed == true) {
      context.read<ChatBloc>().add(const ChatClearHistory());
    }
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
    if (context.mounted && confirmed == true) {
      context.read<ChatBloc>().add(ChatDeleteChat(chat));
    }
  }

  static void _onHeaderTap(BuildContext context, Chat chat) {
    final isMobile = Breakpoints.isMobile(context);
    if (chat.isGroup) {
      final chatBloc = context.read<ChatBloc>();
      final authBloc = context.read<AuthBloc>();
      final screen = BlocProvider.value(
        value: chatBloc,
        child: GroupInfoScreen(
          groupId: chat.peerGroupId,
          groupTitle: chat.title,
          currentUserId: authBloc.state.user?.id,
          isModal: !isMobile,
        ),
      );
      if (isMobile) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => screen));
      } else {
        showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
              child: screen,
            ),
          ),
        );
      }
    } else {
      _showUserCard(context, chat, isMobile);
    }
  }

  static void _showUserCard(BuildContext context, Chat chat, bool isMobile) {
    final content = _buildUserCardContent(context, chat);
    if (isMobile) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Профиль'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Padding(padding: const EdgeInsets.all(24), child: content),
          ),
        ),
      );
    } else {
      showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360, maxHeight: 280),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  content,
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  static Widget _buildUserCardContent(BuildContext context, Chat chat) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          chat.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (chat.userUsername.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '@${chat.userUsername}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (chat.userName.isNotEmpty || chat.userSurname.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '${chat.userName} ${chat.userSurname}'.trim(),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}
