import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/client_local_id.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/domain/entities/attachment_upload.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/usecases/chat/create_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/create_group_chat_usecase.dart';
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
import 'package:voosu/domain/usecases/chat/chat_poll_usecase.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_event.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_state.dart';
import 'package:voosu/presentation/screens/chat/bloc/pending_outgoing_message.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetChatsUseCase getChatsUseCase;
  final CreateChatUseCase createChatUseCase;
  final CreateGroupChatUseCase createGroupChatUseCase;
  final GetChatMessagesUseCase getChatMessagesUseCase;
  final SendChatMessageUseCase sendChatMessageUseCase;
  final SavePendingMessageUseCase savePendingMessageUseCase;
  final GetPendingForChatUseCase getPendingForChatUseCase;
  final RemovePendingMessageUseCase removePendingMessageUseCase;
  final DeleteChatMessagesUseCase deleteChatMessagesUseCase;
  final ClearChatHistoryUseCase clearChatHistoryUseCase;
  final DeleteChatUseCase deleteChatUseCase;
  final ChatPollUseCase chatPollUseCase;
  final AuthBloc authBloc;

  ChatBloc({
    required this.getChatsUseCase,
    required this.createChatUseCase,
    required this.createGroupChatUseCase,
    required this.getChatMessagesUseCase,
    required this.sendChatMessageUseCase,
    required this.savePendingMessageUseCase,
    required this.getPendingForChatUseCase,
    required this.removePendingMessageUseCase,
    required this.deleteChatMessagesUseCase,
    required this.clearChatHistoryUseCase,
    required this.deleteChatUseCase,
    required this.chatPollUseCase,
    required this.authBloc,
  }) : super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatLoadChats>(_onLoadChats);
    on<ChatOpenWithUser>(_onOpenWithUser);
    on<ChatCreateGroupRequested>(_onCreateGroupRequested);
    on<ChatSelectChat>(_onSelectChat);
    on<ChatMessagesForChatLoaded>(_onMessagesForChatLoaded);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatStartSendingMessage>(_onStartSendingMessage);
    on<ChatUploadProgress>(_onUploadProgress);
    on<ChatUploadFileComplete>(_onUploadFileComplete);
    on<ChatSubmitPendingMessage>(_onSubmitPendingMessage);
    on<ChatCancelPendingMessage>(_onCancelPendingMessage);
    on<ChatReplyToMessage>(_onReplyToMessage);
    on<ChatClearReply>(_onClearReply);
    on<ChatForwardMessageToChat>(_onForwardMessageToChat);
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
    on<ChatVotePoll>(_onVotePoll);
    on<ChatCreatePoll>(_onCreatePoll);
  }

  void _onBackToList(ChatBackToList event, Emitter<ChatState> emit) {
    emit(
      state.copyWith(
        clearSelectedChat: true,
        clearSelection: true,
        clearReplyTo: true,
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

  Future<void> _onCreateGroupRequested(
    ChatCreateGroupRequested event,
    Emitter<ChatState> emit,
  ) async {
    if (event.title.trim().isEmpty) {
      emit(state.copyWith(error: 'Введите название группы'));
      return;
    }

    if (event.userIds.isEmpty) {
      emit(state.copyWith(error: 'Добавьте хотя бы одного участника'));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));
    try {
      final chat = await createGroupChatUseCase(
        title: event.title.trim(),
        userIds: event.userIds,
      );
      final chats = await getChatsUseCase();
      emit(state.copyWith(isLoading: false, chats: chats, selectedChat: chat));
      await _loadMessagesForChat(chat, emit);
    } catch (e) {
      Logs().e('ChatBloc: ошибка создания группового чата', e);
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Ошибка создания группового чата',
        ),
      );
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
        clearReplyTo: true,
      ),
    );

    unawaited(_loadAndEmitMessagesForChat(event.chat));
  }

  Future<void> _loadAndEmitMessagesForChat(Chat chat) async {
    List<Message> messages;
    List<Chat> updatedChats;
    List<PendingQueueItem> pendingQueue = const [];
    try {
      final peerUserId = chat.isGroup ? null : chat.peerUserId;
      final peerGroupId = chat.isGroup ? chat.peerGroupId : null;
      messages = await getChatMessagesUseCase(
        peerUserId: peerUserId,
        peerGroupId: peerGroupId,
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
      final peerUserId = chat.isGroup ? null : chat.peerUserId;
      final peerGroupId = chat.isGroup ? chat.peerGroupId : null;
      final messages = await getChatMessagesUseCase(
        peerUserId: peerUserId,
        peerGroupId: peerGroupId,
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

  void _onStartSendingMessage(
    ChatStartSendingMessage event,
    Emitter<ChatState> emit,
  ) {
    final chat = state.selectedChat;
    if (chat == null) {
      return;
    }

    final attachments = <PendingAttachment>[];
    if (event.attachments != null) {
      for (final a in event.attachments!) {
        attachments.add(
          PendingAttachment(
            filename: a.filename,
            size: 0,
            progress: 1,
            fileId: a.fileId,
          ),
        );
      }
    }

    if (event.largeFiles != null) {
      for (final f in event.largeFiles!) {
        attachments.add(
          PendingAttachment(filename: f.filename, size: f.size, progress: 0),
        );
      }
    }

    final pending = PendingOutgoingMessage(
      clientId: event.clientId,
      text: event.text,
      replyToMessageId: event.replyToMessageId,
      attachments: attachments,
    );
    emit(
      state.copyWith(
        pendingOutgoingMessage: pending,
        isSending: true,
        error: null,
      ),
    );
  }

  void _onUploadProgress(ChatUploadProgress event, Emitter<ChatState> emit) {
    final pending = state.pendingOutgoingMessage;
    if (pending == null || pending.clientId != event.clientId) {
      return;
    }

    final progress = event.totalBytes != null && event.totalBytes! > 0
        ? event.sentBytes / event.totalBytes!
        : 0.0;
    final updated = pending.attachments.map((a) {
      if (a.filename != event.filename) {
        return a;
      }

      return a.copyWith(progress: progress.clamp(0.0, 1.0));
    }).toList();
    emit(
      state.copyWith(
        pendingOutgoingMessage: pending.copyWith(attachments: updated),
      ),
    );
  }

  void _onUploadFileComplete(
    ChatUploadFileComplete event,
    Emitter<ChatState> emit,
  ) {
    final pending = state.pendingOutgoingMessage;
    if (pending == null || pending.clientId != event.clientId) {
      return;
    }

    final updated = pending.attachments.map((a) {
      if (a.filename != event.filename) {
        return a;
      }

      return a.copyWith(progress: 1.0, fileId: event.fileId);
    }).toList();
    emit(
      state.copyWith(
        pendingOutgoingMessage: pending.copyWith(attachments: updated),
      ),
    );
  }

  Future<void> _onSubmitPendingMessage(
    ChatSubmitPendingMessage event,
    Emitter<ChatState> emit,
  ) async {
    final pending = state.pendingOutgoingMessage;
    if (pending == null || pending.clientId != event.clientId) {
      return;
    }

    final chat = state.selectedChat;
    if (chat == null) {
      return;
    }

    if (!pending.allAttachmentsReady) {
      return;
    }

    emit(
      state.copyWith(
        pendingOutgoingMessage: pending.copyWith(isSubmitting: true),
      ),
    );

    final attachmentUploads = <AttachmentUpload>[];
    for (final a in pending.attachments) {
      if (a.fileId != null && a.fileId != 0) {
        attachmentUploads.add(
          AttachmentUpload(filename: a.filename, fileId: a.fileId!),
        );
      }
    }

    try {
      final replyToId = pending.replyToMessageId;
      final message = await sendChatMessageUseCase(
        peerUserId: chat.isGroup ? null : chat.peerUserId,
        peerGroupId: chat.isGroup ? chat.peerGroupId : null,
        content: pending.text.isEmpty ? '' : pending.text,
        replyToMessageId: replyToId,
        attachments: attachmentUploads.isEmpty ? null : attachmentUploads,
      );
      final updatedMessages = [...state.messages, message];
      emit(
        state.copyWith(
          isSending: false,
          messages: updatedMessages,
          clearPendingOutgoing: true,
          clearReplyTo: true,
        ),
      );
      add(const ChatLoadChats(silent: true));
    } catch (e) {
      Logs().e('ChatBloc: ошибка отправки сообщения', e);
      try {
        final peerUserId = chat.isGroup
          ? 0
          : chat.peerUserId;
        final peerGroupId = chat.isGroup
          ? chat.peerGroupId
          : 0;
        final attachmentsList = pending.attachments
          .where((a) => a.fileId != null && a.fileId != 0)
          .map((a) => {'filename': a.filename, 'fileId': a.fileId})
          .toList();
        final attachmentsJson = attachmentsList.isEmpty
          ? null
          : jsonEncode(attachmentsList);
        await savePendingMessageUseCase(
          localId: pending.clientId,
          peerUserId: peerUserId,
          peerGroupId: peerGroupId,
          content: pending.text,
          attachmentsJson: attachmentsJson,
          replyToId: pending.replyToMessageId,
        );
        final newItem = PendingQueueItem(
          localId: pending.clientId,
          content: pending.text,
          attachmentsJson: attachmentsJson,
          replyToId: pending.replyToMessageId,
          createdAt: DateTime.now(),
        );
        emit(
          state.copyWith(
            isSending: false,
            pendingQueue: [...state.pendingQueue, newItem],
            error: 'Ошибка отправки. Сообщение добавлено в очередь.',
            clearPendingOutgoing: true,
          ),
        );
      } catch (_) {
        emit(
          state.copyWith(
            isSending: false,
            error: 'Ошибка отправки сообщения',
            clearPendingOutgoing: true,
          ),
        );
      }
    }
  }

  void _onCancelPendingMessage(
    ChatCancelPendingMessage event,
    Emitter<ChatState> emit,
  ) {
    if (state.pendingOutgoingMessage?.clientId != event.clientId) {
      return;
    }
    emit(state.copyWith(clearPendingOutgoing: true, isSending: false));
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
      final replyToId = state.replyTo?.id ?? 0;
      final message = await sendChatMessageUseCase(
        peerUserId: chat.isGroup ? null : chat.peerUserId,
        peerGroupId: chat.isGroup ? chat.peerGroupId : null,
        content: text.isEmpty ? '' : text,
        replyToMessageId: replyToId,
        attachments: event.attachments,
      );
      final updatedMessages = [...state.messages, message];
      emit(
        state.copyWith(
          isSending: false,
          messages: updatedMessages,
          clearReplyTo: true,
        ),
      );
      add(const ChatLoadChats(silent: true));
    } catch (e) {
      Logs().e('ChatBloc: ошибка отправки сообщения', e);
      try {
        final peerUserId = chat.isGroup
            ? 0
            : chat.peerUserId;
        final peerGroupId = chat.isGroup
            ? chat.peerGroupId
            : 0;
        final replyToId = state.replyTo?.id ?? 0;
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
          peerUserId: peerUserId,
          peerGroupId: peerGroupId,
          content: text.isEmpty ? '' : text,
          attachmentsJson: attachmentsJson,
          replyToId: replyToId,
        );
        final newItem = PendingQueueItem(
          localId: localId,
          content: text.isEmpty ? '' : text,
          attachmentsJson: attachmentsJson,
          replyToId: replyToId,
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

  void _onReplyToMessage(ChatReplyToMessage event, Emitter<ChatState> emit) {
    emit(state.copyWith(replyTo: event.message));
  }

  void _onClearReply(ChatClearReply event, Emitter<ChatState> emit) {
    emit(state.copyWith(clearReplyTo: true));
  }

  Future<void> _onForwardMessageToChat(
    ChatForwardMessageToChat event,
    Emitter<ChatState> emit,
  ) async {
    final chat = event.targetChat;
    emit(state.copyWith(isSending: true, error: null));
    try {
      final forwardAttachments = event.message.attachments.isEmpty
          ? null
          : event.message.attachments
                .map(
                  (a) =>
                      AttachmentUpload(filename: a.filename, fileId: a.fileId),
                )
                .toList();
      await sendChatMessageUseCase(
        peerUserId: chat.isGroup ? null : chat.peerUserId,
        peerGroupId: chat.isGroup ? chat.peerGroupId : null,
        content: event.message.content,
        forwarded: true,
        forwardedFromMessageId: event.message.id,
        attachments: forwardAttachments,
      );
      emit(state.copyWith(isSending: false));
      final selectedChat = state.selectedChat;
      if (selectedChat?.id == chat.id) {
        await _loadMessagesForChat(chat, emit);
      }
      Logs().d('ChatBloc: сообщение переслано в чат id=${chat.id}');
      add(const ChatLoadChats(silent: true));
    } catch (e) {
      Logs().e('ChatBloc: ошибка пересылки сообщения', e);
      emit(
        state.copyWith(isSending: false, error: 'Ошибка пересылки сообщения'),
      );
    }
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

  Future<void> _onVotePoll(
    ChatVotePoll event,
    Emitter<ChatState> emit,
  ) async {
    final chat = state.selectedChat;
    if (chat == null || !chat.isGroup) {
      return;
    }

    try {
      await chatPollUseCase.votePoll(
        groupId: chat.peerGroupId,
        messageId: event.messageId,
        optionId: event.optionId,
      );
      await _loadMessagesForChat(chat, emit);
    } on Failure catch (e) {
      emit(state.copyWith(error: e.message));
    } catch (_) {
      emit(state.copyWith(error: 'Не удалось проголосовать'));
    }
  }

  Future<void> _onCreatePoll(
    ChatCreatePoll event,
    Emitter<ChatState> emit,
  ) async {
    final chat = state.selectedChat;
    if (chat == null || !chat.isGroup) {
      emit(state.copyWith(error: 'Опрос можно создать только в группе'));
      return;
    }

    try {
      final message = await chatPollUseCase.createPoll(
        groupId: chat.peerGroupId,
        question: event.question,
        options: event.options,
        anonymous: event.anonymous,
      );
      final updated = List<Message>.from(state.messages)..insert(0, message);
      emit(state.copyWith(messages: updated, error: null));
    } on Failure catch (e) {
      emit(state.copyWith(error: e.message));
    } catch (_) {
      emit(state.copyWith(error: 'Не удалось создать опрос'));
    }
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
      final peerUserId = chat.isGroup ? null : chat.peerUserId;
      final peerGroupId = chat.isGroup ? chat.peerGroupId : null;
      final older = await getChatMessagesUseCase(
        peerUserId: peerUserId,
        peerGroupId: peerGroupId,
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
      final peerUserId = chat.isGroup ? null : chat.peerUserId;
      final peerGroupId = chat.isGroup ? chat.peerGroupId : null;
      await clearChatHistoryUseCase(
        peerUserId: peerUserId,
        peerGroupId: peerGroupId,
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
      final peerUserId = event.chat.isGroup ? null : event.chat.peerUserId;
      final peerGroupId = event.chat.isGroup ? event.chat.peerGroupId : null;
      await deleteChatUseCase(
        peerUserId: peerUserId,
        peerGroupId: peerGroupId,
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
