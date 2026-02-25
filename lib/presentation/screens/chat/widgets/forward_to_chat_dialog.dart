import 'package:flutter/material.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_list_item.dart';

Future<Chat?> showForwardToChatDialog({
  required BuildContext context,
  required List<Chat> chats,
  required Chat? currentChat,
}) async {
  final otherChats = currentChat == null
      ? chats
      : chats.where((c) => c.id != currentChat.id).toList();

  if (otherChats.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет других чатов для пересылки'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return null;
  }

  return showModalBottomSheet<Chat>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Переслать в чат',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: otherChats.length,
              itemBuilder: (context, index) {
                final chat = otherChats[index];
                return ChatListItem(
                  chat: chat,
                  isSelected: false,
                  onTap: () => Navigator.of(context).pop(chat),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
