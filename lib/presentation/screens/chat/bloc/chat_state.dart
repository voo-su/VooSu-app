import 'package:equatable/equatable.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/presentation/screens/chat/bloc/pending_outgoing_message.dart';
import 'package:voosu/domain/entities/chat_mention_member.dart';
import 'package:voosu/domain/entities/pending_queue_item.dart';
import 'package:voosu/domain/entities/user_typing_payload.dart';

class ChatState extends Equatable {
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSending;
  final List<Chat> chats;
  final Chat? selectedChat;
  final List<Message> messages;
  final List<PendingQueueItem> pendingQueue;
  final Set<int> selectedMessageIds;
  final String? error;
  final String? snackbarHint;
  final UserTypingPayload? typing;
  final Message? replyTo;
  final PendingOutgoingMessage? pendingOutgoingMessage;
  final List<ChatMentionMember> groupMentionMembers;

  const ChatState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSending = false,
    this.chats = const [],
    this.selectedChat,
    this.messages = const [],
    this.pendingQueue = const [],
    this.selectedMessageIds = const {},
    this.error,
    this.snackbarHint,
    this.typing,
    this.replyTo,
    this.pendingOutgoingMessage,
    this.groupMentionMembers = const [],
  });

  bool get isSelectionMode => selectedMessageIds.isNotEmpty;

  ChatState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSending,
    List<Chat>? chats,
    Chat? selectedChat,
    bool clearSelectedChat = false,
    List<Message>? messages,
    List<PendingQueueItem>? pendingQueue,
    bool clearPendingQueue = false,
    Set<int>? selectedMessageIds,
    bool clearSelection = false,
    String? error,
    String? snackbarHint,
    bool clearSnackbarHint = false,
    UserTypingPayload? typing,
    bool clearTyping = false,
    Message? replyTo,
    bool clearReplyTo = false,
    PendingOutgoingMessage? pendingOutgoingMessage,
    bool clearPendingOutgoing = false,
    List<ChatMentionMember>? groupMentionMembers,
    bool clearGroupMentionMembers = false,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
      chats: chats ?? this.chats,
      selectedChat: clearSelectedChat
          ? null
          : (selectedChat ?? this.selectedChat),
      messages: messages ?? this.messages,
      pendingQueue: clearPendingQueue
          ? const []
          : (pendingQueue ?? this.pendingQueue),
      selectedMessageIds: clearSelection
          ? const {}
          : (selectedMessageIds ?? this.selectedMessageIds),
      error: error,
      snackbarHint: clearSnackbarHint ? null : (snackbarHint ?? this.snackbarHint),
      typing: clearTyping ? null : (typing ?? this.typing),
      replyTo: clearReplyTo ? null : (replyTo ?? this.replyTo),
      pendingOutgoingMessage: clearPendingOutgoing
          ? null
          : (pendingOutgoingMessage ?? this.pendingOutgoingMessage),
      groupMentionMembers: clearGroupMentionMembers
          ? const []
          : (groupMentionMembers ?? this.groupMentionMembers),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isLoadingMore,
    isSending,
    chats,
    selectedChat,
    messages,
    pendingQueue,
    selectedMessageIds,
    error,
    snackbarHint,
    typing,
    replyTo,
    pendingOutgoingMessage,
    groupMentionMembers,
  ];
}
