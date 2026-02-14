import 'package:flutter/material.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/entities/pending_queue_item.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_delete_scope_dialog.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_empty_placeholders.dart';
import 'package:voosu/presentation/screens/chat/widgets/message_bubble.dart';
import 'package:voosu/presentation/screens/chat/widgets/queued_message_bubble.dart';
import 'package:voosu/presentation/screens/chat/widgets/service_message_widget.dart';
import 'package:voosu/presentation/widgets/loading_placeholder.dart';

class ChatMessagesList extends StatelessWidget {
  final Chat? selectedChat;
  final List<Message> messages;
  final List<PendingQueueItem> pendingQueue;
  final bool isLoading;
  final Set<int> selectedMessageIds;
  final ScrollController scrollController;
  final int currentUserId;
  final Future<void> Function(Message message, bool forEveryone) onDeleteMessage;
  final void Function(Message message) onToggleMessageSelection;
  final Future<void> Function(String localId) onCancelPending;

  const ChatMessagesList({
    super.key,
    required this.selectedChat,
    required this.messages,
    required this.pendingQueue,
    required this.isLoading,
    required this.selectedMessageIds,
    required this.scrollController,
    required this.currentUserId,
    required this.onDeleteMessage,
    required this.onToggleMessageSelection,
    required this.onCancelPending,
  });

  bool get _isSelectionMode => selectedMessageIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (selectedChat == null) {
      return const ChatEmptyPlaceholder();
    }

    final hasQueue = pendingQueue.isNotEmpty;
    if (isLoading && messages.isEmpty && !hasQueue) {
      return const LoadingPlaceholder();
    }

    if (messages.isEmpty && !hasQueue) {
      return const ChatEmptyMessagesPlaceholder();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? theme.colorScheme.surface
        : theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.5);

    final sentBubbleColor = isDark
        ? const Color(0xFF2E6B9E)
        : theme.colorScheme.primary;
    final sentTextColor = theme.colorScheme.onPrimary;
    final timeColor = sentTextColor.withValues(alpha: 0.85);

    final messagesCount = messages.length;
    final queueCount = pendingQueue.length;
    final totalCount = messagesCount + queueCount;

    return Container(
      color: bgColor,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        itemCount: totalCount,
        itemBuilder: (context, index) {
          if (index < messagesCount) {
            final message = messages[index];
            if (message.isSystemMessage) {
              return ServiceMessageWidget(message: message);
            }

            final isFromMe =
                currentUserId != 0 && message.senderId == currentUserId;
            final isSelected = selectedMessageIds.contains(message.id);

            return MessageBubble(
              message: message,
              isFromMe: isFromMe,
              onDelete: () async {
                final forEveryone = await showDeleteScopeDialog(
                  context,
                  isFromMe: isFromMe,
                );
                if (context.mounted && forEveryone != null) {
                  await onDeleteMessage(message, forEveryone);
                }
              },
              isSelectionMode: _isSelectionMode,
              isSelected: isSelected,
              onToggleSelection: isFromMe
                  ? () => onToggleMessageSelection(message)
                  : null,
            );
          }

          if (index >= messagesCount && index < messagesCount + queueCount) {
            final queueItem = pendingQueue[index - messagesCount];
            return QueuedMessageBubble(
              item: queueItem,
              bubbleColor: sentBubbleColor,
              textColor: sentTextColor,
              timeColor: timeColor,
              onCancel: () => onCancelPending(queueItem.localId),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
