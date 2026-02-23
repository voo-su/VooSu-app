import 'package:equatable/equatable.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/entities/pending_queue_item.dart';

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
  ];
}
