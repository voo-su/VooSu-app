import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/client_local_id.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/usecases/chat/create_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/clear_chat_history_usecase.dart';
import 'package:voosu/domain/usecases/chat/delete_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/delete_chat_messages_usecase.dart';
import 'package:voosu/domain/usecases/chat/get_chat_messages_usecase.dart';
import 'package:voosu/domain/entities/pending_queue_item.dart';
import 'package:voosu/domain/usecases/chat/get_chats_usecase.dart';
import 'package:voosu/domain/usecases/chat/get_pending_for_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/remove_pending_message_usecase.dart';
import 'package:voosu/domain/usecases/chat/save_pending_message_usecase.dart';
import 'package:voosu/domain/usecases/chat/send_chat_message_usecase.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_event.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetChatsUseCase getChatsUseCase;
  final CreateChatUseCase createChatUseCase;
  final GetChatMessagesUseCase getChatMessagesUseCase;
  final SendChatMessageUseCase sendChatMessageUseCase;
  final SavePendingMessageUseCase savePendingMessageUseCase;
  final GetPendingForChatUseCase getPendingForChatUseCase;
  final RemovePendingMessageUseCase removePendingMessageUseCase;
  final DeleteChatMessagesUseCase deleteChatMessagesUseCase;
  final ClearChatHistoryUseCase clearChatHistoryUseCase;
  final DeleteChatUseCase deleteChatUseCase;
  final AuthBloc authBloc;

  ChatBloc({
    required this.getChatsUseCase,
    required this.createChatUseCase,
    required this.getChatMessagesUseCase,
    required this.sendChatMessageUseCase,
    required this.savePendingMessageUseCase,
    required this.getPendingForChatUseCase,
    required this.removePendingMessageUseCase,
    required this.deleteChatMessagesUseCase,
    required this.clearChatHistoryUseCase,
    required this.deleteChatUseCase,
    required this.authBloc,
  }) : super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatLoadChats>(_onLoadChats);
    on<ChatOpenWithUser>(_onOpenWithUser);
    on<ChatSelectChat>(_onSelectChat);
    on<ChatMessagesForChatLoaded>(_onMessagesForChatLoaded);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatClearError>(_onClearError);
    on<ChatBackToList>(_onBackToList);
    on<ChatDeleteMessage>(_onDeleteMessage);
    on<ChatToggleMessageSelection>(_onToggleMessageSelection);
    on<ChatDeleteSelectedMessages>(_onDeleteSelectedMessages);
    on<ChatClearSelection>(_onClearSelection);
    on<ChatSelectAllMyMessages>(_onSelectAllMyMessages);
    on<ChatClearHistory>(_onClearHistory);
    on<ChatDeleteChat>(_onDeleteChat);
    on<ChatLoadMoreMessages>(_onLoadMoreMessages);
    on<ChatCancelPendingFromQueue>(_onCancelPendingFromQueue);
  }

  void _onBackToList(ChatBackToList event, Emitter<ChatState> emit) {
    emit(
      state.copyWith(
        clearSelectedChat: true,
        clearSelection: true,
      ),
    );
  }

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    await _loadChatsInternal(emit);
  }

  Future<void> _onLoadChats(
    ChatLoadChats event,
    Emitter<ChatState> emit,
  ) async {
    await _loadChatsInternal(emit, silent: event.silent);
  }

  Future<void> _loadChatsInternal(
    Emitter<ChatState> emit, {
    bool silent = false,
  }) async {
    if (!silent) {
      emit(state.copyWith(isLoading: true, error: null));
    }

    try {
      final chats = await getChatsUseCase();
      emit(
        state.copyWith(
          isLoading: false,
          chats: chats,
          error: silent ? state.error : null,
        ),
      );
    } catch (e) {
      Logs().e('ChatBloc: ошибка загрузки чатов', e);
      final fallbackChats = state.chats;
      if (!silent) {
        emit(state.copyWith(
          isLoading: false,
          chats: fallbackChats,
          error: fallbackChats.isEmpty ? 'Ошибка загрузки чатов' : null,
        ));
      } else {
        emit(state.copyWith(isLoading: false, chats: fallbackChats));
      }
    }
  }

  Future<void> _onOpenWithUser(
    ChatOpenWithUser event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final chat = await createChatUseCase(event.userId);
      final chats = await getChatsUseCase();
      emit(state.copyWith(isLoading: false, chats: chats, selectedChat: chat));
      await _loadMessagesForChat(chat, emit);
    } catch (e) {
      Logs().e('ChatBloc: ошибка открытия чата с пользователем', e);
      emit(state.copyWith(isLoading: false, error: 'Ошибка открытия чата'));
    }
  }

  Future<void> _onSelectChat(
    ChatSelectChat event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedChat: event.chat,
        messages: const [],
        pendingQueue: const [],
        isLoading: true,
        error: null,
        clearSelection: true,
      ),
    );

    unawaited(_loadAndEmitMessagesForChat(event.chat));
  }

  Future<void> _loadAndEmitMessagesForChat(Chat chat) async {
    List<Message> messages;
    List<Chat> updatedChats;
    List<PendingQueueItem> pendingQueue = const [];
    try {
      messages = await getChatMessagesUseCase(
        peerUserId: chat.peerUserId,
        messageId: 0,
        limit: 100,
      );
      updatedChats = state.chats
        .map((c) => c.id == chat.id ? c.copyWith(unreadCount: 0) : c)
        .toList();
      pendingQueue = await getPendingForChatUseCase(chat.id);
    } catch (e) {
      Logs().e('ChatBloc: ошибка загрузки сообщений', e);
      messages = state.messages;
      updatedChats = state.chats;
    }
    add(ChatMessagesForChatLoaded(
      chat: chat,
      messages: messages,
      updatedChats: updatedChats,
      pendingQueue: pendingQueue,
    ));
  }

  void _onMessagesForChatLoaded(
    ChatMessagesForChatLoaded event,
    Emitter<ChatState> emit,
  ) {
    if (state.selectedChat?.id != event.chat.id) {
      return;
    }

    final merged = List<Message>.from(event.messages)
      ..sort((a, b) => a.id.compareTo(b.id));
    emit(
      state.copyWith(
        messages: merged,
        chats: event.updatedChats,
        pendingQueue: event.pendingQueue,
        isLoading: false,
      ),
    );
  }

  Future<void> _loadMessagesForChat(Chat chat, Emitter<ChatState> emit) async {
    try {
      final messages = await getChatMessagesUseCase(
        peerUserId: chat.peerUserId,
        messageId: 0,
        limit: 100,
      );

      final updatedChats = state.chats
          .map((c) => c.id == chat.id ? c.copyWith(unreadCount: 0) : c)
          .toList();
      emit(
        state.copyWith(
          messages: messages,
          isLoading: false,
          chats: updatedChats,
        ),
      );
      await _loadPendingQueueForChat(chat.id, emit);
    } catch (e) {
      Logs().e('ChatBloc: ошибка загрузки сообщений', e);
      emit(state.copyWith(messages: state.messages, isLoading: false));
      await _loadPendingQueueForChat(chat.id, emit);
    }
  }

  Future<void> _loadPendingQueueForChat(
    int chatId,
    Emitter<ChatState> emit,
  ) async {
    try {
      final queue = await getPendingForChatUseCase(chatId);
      emit(state.copyWith(pendingQueue: queue));
    } catch (_) {}
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final text = event.text.trim();
    final hasAttachments =
        event.attachments != null && event.attachments!.isNotEmpty;
    if (text.isEmpty && !hasAttachments) {
      return;
    }
    final chat = state.selectedChat;
    if (chat == null) {
      emit(state.copyWith(error: 'Чат не выбран'));
      return;
    }

    emit(state.copyWith(isSending: true, error: null));
    try {
      final message = await sendChatMessageUseCase(
        peerUserId: chat.peerUserId,
        content: text.isEmpty ? '' : text,
        attachments: event.attachments,
      );
      final updatedMessages = [...state.messages, message];
      emit(
        state.copyWith(
          isSending: false,
          messages: updatedMessages,
        ),
      );
      add(const ChatLoadChats(silent: true));
    } catch (e) {
      Logs().e('ChatBloc: ошибка отправки сообщения', e);
      try {
        final attachmentsJson =
            (event.attachments != null && event.attachments!.isNotEmpty)
            ? jsonEncode(
                event.attachments!
                    .map((a) => {'filename': a.filename, 'fileId': a.fileId})
                    .toList(),
              )
            : null;
        final localId = newClientLocalId();
        await savePendingMessageUseCase(
          localId: localId,
          peerUserId: chat.peerUserId,
          content: text.isEmpty ? '' : text,
          attachmentsJson: attachmentsJson,
        );
        final newItem = PendingQueueItem(
          localId: localId,
          content: text.isEmpty ? '' : text,
          attachmentsJson: attachmentsJson,
          createdAt: DateTime.now(),
        );
        emit(
          state.copyWith(
            isSending: false,
            pendingQueue: [...state.pendingQueue, newItem],
          ),
        );
      } catch (_) {
        emit(
          state.copyWith(isSending: false, error: 'Ошибка отправки сообщения'),
        );
      }
    }
  }

  Future<void> _onCancelPendingFromQueue(
    ChatCancelPendingFromQueue event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await removePendingMessageUseCase(event.localId);
      emit(
        state.copyWith(
          pendingQueue: state.pendingQueue
              .where((q) => q.localId != event.localId)
              .toList(),
        ),
      );
    } catch (_) {}
  }

  void _onClearError(ChatClearError event, Emitter<ChatState> emit) {
    emit(state.copyWith(error: null));
  }

  Future<void> _onDeleteMessage(
    ChatDeleteMessage event,
    Emitter<ChatState> emit,
  ) async {
    final message = event.message;
    final chat = state.selectedChat;
    if (chat == null) {
      return;
    }

    emit(state.copyWith(error: null));
    try {
      await deleteChatMessagesUseCase([
        message.id,
      ], forEveryone: event.forEveryone);
      final updated = state.messages.where((m) => m.id != message.id).toList();
      emit(state.copyWith(messages: updated));
      add(const ChatLoadChats(silent: true));
    } catch (e) {
      Logs().e('ChatBloc: ошибка удаления сообщения', e);
      emit(state.copyWith(error: 'Ошибка удаления сообщения'));
    }
  }

  void _onToggleMessageSelection(
    ChatToggleMessageSelection event,
    Emitter<ChatState> emit,
  ) {
    final id = event.message.id;
    final next = Set<int>.from(state.selectedMessageIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    emit(state.copyWith(selectedMessageIds: next));
  }

  Future<void> _onDeleteSelectedMessages(
    ChatDeleteSelectedMessages event,
    Emitter<ChatState> emit,
  ) async {
    final ids = state.selectedMessageIds.toList();
    if (ids.isEmpty) {
      return;
    }

    emit(state.copyWith(error: null));
    try {
      await deleteChatMessagesUseCase(ids, forEveryone: event.forEveryone);
      final idSet = state.selectedMessageIds;
      final updated = state.messages
          .where((m) => !idSet.contains(m.id))
          .toList();
      emit(state.copyWith(messages: updated, clearSelection: true));
      add(const ChatLoadChats(silent: true));
    } catch (e) {
      Logs().e('ChatBloc: ошибка удаления сообщений', e);
      emit(state.copyWith(error: 'Ошибка удаления сообщений'));
    }
  }

  void _onClearSelection(ChatClearSelection event, Emitter<ChatState> emit) {
    emit(state.copyWith(clearSelection: true));
  }

  void _onSelectAllMyMessages(
    ChatSelectAllMyMessages event,
    Emitter<ChatState> emit,
  ) {
    final currentUserId = authBloc.state.user?.id ?? 0;

    final myIds = state.messages
        .where((m) => m.senderId == currentUserId)
        .map((m) => m.id)
        .toSet();
    emit(state.copyWith(selectedMessageIds: myIds));
  }

  Future<void> _onLoadMoreMessages(
    ChatLoadMoreMessages event,
    Emitter<ChatState> emit,
  ) async {
    final chat = state.selectedChat;
    if (chat == null || state.messages.isEmpty || state.isLoadingMore) {
      return;
    }

    final oldestId = state.messages
        .map((m) => m.id)
        .reduce((a, b) => a < b ? a : b);

    emit(state.copyWith(isLoadingMore: true));
    try {
      final older = await getChatMessagesUseCase(
        peerUserId: chat.peerUserId,
        messageId: oldestId,
        limit: 50,
      );

      if (older.isEmpty) {
        emit(state.copyWith(isLoadingMore: false));
        return;
      }

      final merged = [...older, ...state.messages];
      emit(state.copyWith(messages: merged, isLoadingMore: false));
    } catch (e) {
      Logs().e('ChatBloc: ошибка подгрузки сообщений', e);
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onClearHistory(
    ChatClearHistory event,
    Emitter<ChatState> emit,
  ) async {
    final chat = state.selectedChat;
    if (chat == null) {
      return;
    }

    emit(state.copyWith(error: null));
    try {
      await clearChatHistoryUseCase(
        peerUserId: chat.peerUserId,
      );
      emit(state.copyWith(messages: const []));
      add(const ChatLoadChats(silent: true));
    } catch (e) {
      Logs().e('ChatBloc: ошибка очистки истории', e);
      emit(state.copyWith(error: 'Ошибка очистки истории'));
    }
  }

  Future<void> _onDeleteChat(
    ChatDeleteChat event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(error: null));
    try {
      await deleteChatUseCase(
        peerUserId: event.chat.peerUserId,
      );
      final updatedChats = state.chats.where((c) => c.id != event.chat.id).toList();
      final isDeletingSelected = state.selectedChat?.id == event.chat.id;
      emit(state.copyWith(
        chats: updatedChats,
        selectedChat: isDeletingSelected ? null : state.selectedChat,
        messages: isDeletingSelected ? const [] : state.messages,
      ));
    } catch (e) {
      Logs().e('ChatBloc: ошибка удаления чата', e);
      emit(state.copyWith(error: 'Ошибка удаления чата'));
    }
  }
}
