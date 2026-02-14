import 'package:flutter/material.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_list_avatar.dart';

class ChatListItem extends StatelessWidget {
  final Chat chat;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDeleteChat;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.isSelected,
    required this.onTap,
    this.onDeleteChat,
  });

  static String title(Chat chat) {
    if (chat.title.isNotEmpty) return chat.title;
    if (chat.userUsername.isNotEmpty) return chat.userUsername;
    return '${chat.userName} ${chat.userSurname}'.trim();
  }

  static String _subtitle(Chat chat) {
    final lastPreview = chat.lastMessagePreview;
    if (lastPreview != null && lastPreview.isNotEmpty) {
      return lastPreview;
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStr = title(chat);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isSelected
          ? (isDark
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
                : theme.colorScheme.primaryContainer.withValues(alpha: 0.35))
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onDeleteChat != null
            ? () => _showContextMenu(context, theme)
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              ChatListAvatar(
                title: titleStr,
                avatarFileId: chat.avatarFileId,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titleStr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_subtitle(chat).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(chat),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.75,
                          ),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (chat.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, ThemeData theme) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDeleteChat != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Удалить чат'),
                onTap: () {
                  Navigator.of(context).pop();
                  onDeleteChat?.call();
                },
              ),
          ],
        ),
      ),
    );
  }
}
