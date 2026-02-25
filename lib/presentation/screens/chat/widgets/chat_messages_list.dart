import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_event.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_state.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_delete_scope_dialog.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_empty_placeholders.dart';
import 'package:voosu/presentation/screens/chat/widgets/message_bubble.dart';
import 'package:voosu/presentation/screens/chat/widgets/queued_message_bubble.dart';
import 'package:voosu/presentation/screens/chat/widgets/sending_message_bubble.dart';
import 'package:voosu/presentation/screens/chat/widgets/service_message_widget.dart';
import 'package:voosu/presentation/widgets/loading_placeholder.dart';

Message? _findMessage(List<Message> messages, int id) {
  try {
    return messages.firstWhere((m) => m.id == id);
  } catch (_) {
    return null;
  }
}

class ChatMessagesList extends StatelessWidget {
  final ChatState state;
  final ScrollController scrollController;
  final void Function(Message)? onReply;
  final void Function(Message)? onForward;
  final Future<void> Function(int fileId, String filename)?
  onDownloadAttachment;

  const ChatMessagesList({
    super.key,
    required this.state,
    required this.scrollController,
    this.onReply,
    this.onForward,
    this.onDownloadAttachment,
  });

  @override
  Widget build(BuildContext context) {
    if (state.selectedChat == null) {
      return const ChatEmptyPlaceholder();
    }

    final hasQueue = state.pendingQueue.isNotEmpty;
    final hasPending = state.pendingOutgoingMessage != null;
    if (state.isLoading && state.messages.isEmpty && !hasQueue && !hasPending) {
      return const LoadingPlaceholder();
    }

    if (state.messages.isEmpty && !hasQueue && !hasPending) {
      return const ChatEmptyMessagesPlaceholder();
    }

    final currentUserId = context.read<AuthBloc>().state.user?.id;
    final currentUserInt = currentUserId ?? 0;

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

    final messagesCount = state.messages.length;
    final queueCount = state.pendingQueue.length;
    final totalCount = messagesCount + queueCount + (hasPending ? 1 : 0);

    return Container(
      color: bgColor,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        itemCount: totalCount,
        itemBuilder: (context, index) {
          if (index < messagesCount) {
            final message = state.messages[index];
            if (message.isSystemMessage) {
              return ServiceMessageWidget(message: message);
            }

            final isFromMe = currentUserInt != 0 && message.senderId == currentUserInt;
            final isSelected = state.selectedMessageIds.contains(message.id);
            final replyToMessage = message.replyToMessageId > 0
              ? _findMessage(state.messages, message.replyToMessageId)
              : null;
            final chatTitle = state.selectedChat?.title ?? 'Пользователь';
            String? senderNameFor(int userId) {
              if (currentUserInt == 0) {
                return null;
              }

              return userId == currentUserInt ? 'Вы' : chatTitle;
            }

            return MessageBubble(
              message: message,
              isFromMe: isFromMe,
              replyToMessage: replyToMessage,
              replyToSenderName: replyToMessage != null
                ? senderNameFor(replyToMessage.fromPeerUserId)
                : null,
              forwardedSenderName: message.forwarded
                ? senderNameFor(message.fromPeerUserId)
                : null,
              onReply: onReply != null ? () => onReply?.call(message) : null,
              onForward: onForward != null
                ? () => onForward?.call(message)
                : null,
              onDownloadAttachment: onDownloadAttachment,
              onDelete: () async {
                final forEveryone = await showDeleteScopeDialog(
                  context,
                  isFromMe: isFromMe,
                );
                if (context.mounted && forEveryone != null) {
                  context.read<ChatBloc>().add(
                    ChatDeleteMessage(message, forEveryone: forEveryone),
                  );
                }
              },
              isSelectionMode: state.isSelectionMode,
              isSelected: isSelected,
              onToggleSelection: isFromMe
                  ? () => context.read<ChatBloc>().add(
                      ChatToggleMessageSelection(message),
                    )
                  : null,
            );
          }

          if (index >= messagesCount && index < messagesCount + queueCount) {
            final queueItem = state.pendingQueue[index - messagesCount];
            return QueuedMessageBubble(
              item: queueItem,
              bubbleColor: sentBubbleColor,
              textColor: sentTextColor,
              timeColor: timeColor,
              onCancel: () => context.read<ChatBloc>().add(
                ChatCancelPendingFromQueue(queueItem.localId),
              ),
            );
          }

          if (hasPending && index == messagesCount + queueCount) {
            return SendingMessageBubble(
              pending: state.pendingOutgoingMessage!,
              bubbleColor: sentBubbleColor,
              textColor: sentTextColor,
              timeColor: timeColor,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
