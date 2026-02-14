import 'package:flutter/material.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_list_item.dart';
import 'package:voosu/presentation/widgets/loading_placeholder.dart';

class ChatListWidget extends StatelessWidget {
  final List<Chat> chats;
  final Chat? selectedChat;
  final bool isLoading;
  final void Function(Chat chat) onSelectChat;
  final void Function(Chat chat) onDeleteChat;

  const ChatListWidget({
    super.key,
    required this.chats,
    required this.selectedChat,
    required this.isLoading,
    required this.onSelectChat,
    required this.onDeleteChat,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && chats.isEmpty) {
      return const LoadingPlaceholder();
    }

    if (chats.isEmpty) {
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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: chats.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: 60,
      ),
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatListItem(
          chat: chat,
          isSelected: chat == selectedChat,
          onTap: () => onSelectChat(chat),
          onDeleteChat: () => _showDeleteChatConfirm(context, chat),
        );
      },
    );
  }

  Future<void> _showDeleteChatConfirm(BuildContext context, Chat chat) async {
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
      onDeleteChat(chat);
    }
  }
}
