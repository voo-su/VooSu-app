import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/client_local_id.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/data_sources/local/chat_draft_local_data_source.dart';
import 'package:voosu/data/data_sources/local/chat_notification_settings_local_data_source.dart';
import 'package:voosu/data/services/notification_sound_service.dart';
import 'package:voosu/domain/entities/attachment_upload.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/entities/message_deleted_payload.dart';
import 'package:voosu/domain/entities/message_read_payload.dart';
import 'package:voosu/domain/usecases/chat/create_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/create_group_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/clear_chat_history_usecase.dart';
import 'package:voosu/domain/usecases/chat/delete_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/delete_chat_messages_usecase.dart';
import 'package:voosu/domain/usecases/chat/get_chat_messages_usecase.dart';
import 'package:voosu/domain/entities/pending_queue_item.dart';
import 'package:voosu/domain/entities/user_typing_payload.dart';
import 'package:voosu/domain/usecases/chat/get_chats_usecase.dart';
import 'package:voosu/domain/usecases/chat/get_group_mention_members_usecase.dart';
import 'package:voosu/domain/usecases/chat/get_pending_for_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/remove_pending_message_usecase.dart';
import 'package:voosu/domain/usecases/chat/save_pending_message_usecase.dart';
import 'package:voosu/domain/usecases/chat/send_chat_message_usecase.dart';
import 'package:voosu/domain/usecases/chat/send_chat_code_usecase.dart';
import 'package:voosu/domain/usecases/chat/send_chat_location_usecase.dart';
import 'package:voosu/domain/usecases/chat/send_chat_sticker_usecase.dart';
import 'package:voosu/domain/usecases/chat/send_chat_typing_usecase.dart';
import 'package:voosu/domain/usecases/chat/report_inline_callback_usecase.dart';
import 'package:voosu/domain/usecases/chat/chat_poll_usecase.dart';
import 'package:voosu/domain/usecases/chat/set_chat_notifications_usecase.dart';
import 'package:voosu/domain/usecases/chat/set_chat_pin_usecase.dart';
import 'package:voosu/domain/usecases/chat/leave_group_usecase.dart';
import 'package:voosu/domain/usecases/chat/clear_unread_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/collect_sticker_from_message_usecase.dart';
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
  final SendChatStickerUseCase sendChatStickerUseCase;
  final SendChatCodeUseCase sendChatCodeUseCase;
  final SendChatLocationUseCase sendChatLocationUseCase;
  final SavePendingMessageUseCase savePendingMessageUseCase;
  final GetPendingForChatUseCase getPendingForChatUseCase;
  final GetGroupMentionMembersUseCase getGroupMentionMembersUseCase;
  final RemovePendingMessageUseCase removePendingMessageUseCase;
  final DeleteChatMessagesUseCase deleteChatMessagesUseCase;
  final ClearChatHistoryUseCase clearChatHistoryUseCase;
  final DeleteChatUseCase deleteChatUseCase;
  final SendChatTypingUseCase sendChatTypingUseCase;
  final SetChatNotificationsUseCase setChatNotificationsUseCase;
  final SetChatPinUseCase setChatPinUseCase;
  final LeaveGroupUseCase leaveGroupUseCase;
  final ClearUnreadChatUseCase clearUnreadChatUseCase;
  final CollectStickerFromMessageUseCase collectStickerFromMessageUseCase;
  final ReportInlineCallbackUseCase reportInlineCallbackUseCase;
  final ChatPollUseCase chatPollUseCase;
  final ChatDraftLocalDataSource chatDraftLocal;
  final AuthBloc authBloc;
  final NotificationSoundService? notificationSoundService;
  final ChatNotificationSettingsLocalDataSource? chatNotificationSettings;
  StreamSubscription<Message>? _newMessageSubscription;
  StreamSubscription<MessageDeletedPayload>? _messageDeletedSubscription;
  StreamSubscription<MessageReadPayload>? _messageReadSubscription;
  StreamSubscription<UserTypingPayload>? _userTypingSubscription;
  StreamSubscription<Object?>? _chatListRefreshSubscription;
  StreamSubscription<Object?>? _syncRestoredSubscription;
  Timer? _typingClearTimer;
  Timer? _chatListRefreshDebounce;

  ChatBloc({
    required this.getChatsUseCase,
    required this.createChatUseCase,
    required this.createGroupChatUseCase,
    required this.getChatMessagesUseCase,
    required this.sendChatMessageUseCase,
    required this.sendChatStickerUseCase,
    required this.sendChatCodeUseCase,
    required this.sendChatLocationUseCase,
    required this.savePendingMessageUseCase,
    required this.getPendingForChatUseCase,
    required this.getGroupMentionMembersUseCase,
    required this.removePendingMessageUseCase,
    required this.deleteChatMessagesUseCase,
    required this.clearChatHistoryUseCase,
    required this.deleteChatUseCase,
    required this.sendChatTypingUseCase,
    required this.setChatNotificationsUseCase,
    required this.setChatPinUseCase,
    required this.leaveGroupUseCase,
    required this.clearUnreadChatUseCase,
    required this.collectStickerFromMessageUseCase,
    required this.reportInlineCallbackUseCase,
    required this.chatPollUseCase,
    required this.chatDraftLocal,
    required this.authBloc,
    this.notificationSoundService,
    this.chatNotificationSettings,
    Stream<Message>? newMessageStream,
    Stream<MessageDeletedPayload>? messageDeletedStream,
    Stream<MessageReadPayload>? messageReadStream,
    Stream<UserTypingPayload>? userTypingStream,
    Stream<Object?>? chatListRefreshStream,
    Stream<Object?>? syncRestoredStream,
  }) : super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatLoadChats>(_onLoadChats);
    on<ChatOpenWithUser>(_onOpenWithUser);
    on<ChatOpenGroupById>(_onOpenGroupById);
    on<ChatCreateGroupRequested>(_onCreateGroupRequested);
    on<ChatSelectChat>(_onSelectChat);
    on<ChatGroupMentionMembersLoaded>(_onGroupMentionMembersLoaded);
    on<ChatMessagesForChatLoaded>(_onMessagesForChatLoaded);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatSendSticker>(_onSendSticker);
    on<ChatSendCode>(_onSendCode);
    on<ChatSendLocation>(_onSendLocation);
    on<ChatStartSendingMessage>(_onStartSendingMessage);
    on<ChatUploadProgress>(_onUploadProgress);
    on<ChatUploadFileComplete>(_onUploadFileComplete);
    on<ChatSubmitPendingMessage>(_onSubmitPendingMessage);
    on<ChatCancelPendingMessage>(_onCancelPendingMessage);
    on<ChatReplyToMessage>(_onReplyToMessage);
    on<ChatClearReply>(_onClearReply);
    on<ChatForwardMessageToChat>(_onForwardMessageToChat);
    on<ChatClearError>(_onClearError);
    on<ChatClearSnackbarHint>(_onClearSnackbarHint);
    on<ChatCollectStickerFromMessage>(_onCollectStickerFromMessage);
    on<ChatBackToList>(_onBackToList);
    on<ChatToggleChatNotifications>(_onToggleChatNotifications);
    on<ChatTogglePin>(_onTogglePin);
    on<ChatLeaveGroup>(_onLeaveGroup);
    on<ChatGroupLeftApplied>(_onGroupLeftApplied);
    on<ChatNewMessageReceived>(_onNewMessageReceived);
    on<ChatDeleteMessage>(_onDeleteMessage);
    on<ChatToggleMessageSelection>(_onToggleMessageSelection);
    on<ChatDeleteSelectedMessages>(_onDeleteSelectedMessages);
    on<ChatClearSelection>(_onClearSelection);
    on<ChatSelectAllMyMessages>(_onSelectAllMyMessages);
    on<ChatMessagesDeletedFromServer>(_onMessagesDeletedFromServer);
    on<ChatMessagesRead>(_onMessagesRead);
    on<ChatUserTyping>(_onUserTyping);
    on<ChatClearTyping>(_onClearTyping);
    on<ChatSendTyping>(_onSendTyping);
    on<ChatClearHistory>(_onClearHistory);
    on<ChatDeleteChat>(_onDeleteChat);
    on<ChatLoadMoreMessages>(_onLoadMoreMessages);
    on<ChatSyncRestored>(_onSyncRestored);
    on<ChatCancelPendingFromQueue>(_onCancelPendingFromQueue);
    on<ChatInlineCallbackPressed>(_onInlineCallbackPressed);
    on<ChatVotePoll>(_onVotePoll);
    on<ChatCreatePoll>(_onCreatePoll);

    if (newMessageStream != null) {
      _newMessageSubscription = newMessageStream.listen((message) {
        add(ChatNewMessageReceived(message));
      });
    }

    if (messageDeletedStream != null) {
      _messageDeletedSubscription = messageDeletedStream.listen((payload) {
        add(
          ChatMessagesDeletedFromServer(
            peerId: payload.peerId,
            fromPeerId: payload.fromPeerId,
            messageIds: payload.messageIds,
          ),
        );
      });
    }

    if (messageReadStream != null) {
      _messageReadSubscription = messageReadStream.listen((payload) {
        add(
          ChatMessagesRead(
            readerUserId: payload.readerUserId,
            peerUserId: payload.peerUserId,
            lastReadMessageId: payload.lastReadMessageId,
          ),
        );
      });
    }

    if (userTypingStream != null) {
      _userTypingSubscription = userTypingStream.listen((payload) {
        add(ChatUserTyping(payload));
      });
    }

    if (chatListRefreshStream != null) {
      _chatListRefreshSubscription = chatListRefreshStream.listen((_) {
        _chatListRefreshDebounce?.cancel();
        _chatListRefreshDebounce = Timer(const Duration(milliseconds: 150), () {
          add(const ChatLoadChats(silent: true));
        });
      });
    }

    if (syncRestoredStream != null) {
      _syncRestoredSubscription = syncRestoredStream.listen((_) {
        add(const ChatSyncRestored());
      });
    }
  }

  @override
  Future<void> close() {
    _typingClearTimer?.cancel();
    _chatListRefreshDebounce?.cancel();
    _chatListRefreshSubscription?.cancel();
    _syncRestoredSubscription?.cancel();
    _newMessageSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _messageReadSubscription?.cancel();
    _userTypingSubscription?.cancel();
    return super.close();
  }

  void _onBackToList(ChatBackToList event, Emitter<ChatState> emit) {
    emit(
      state.copyWith(
        clearSelectedChat: true,
        clearSelection: true,
        clearReplyTo: true,
        clearGroupMentionMembers: true,
      ),
    );
  }

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    try {
      final cached = await getChatsUseCase.getCachedChats();
      if (cached.isNotEmpty) {
        emit(state.copyWith(chats: sortChatsForList(cached), isLoading: false));
      }
    } catch (_) {}
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
          chats: sortChatsForList(chats),
          error: silent ? state.error : null,
        ),
      );
      await _syncNotificationSettingsFromServer(chats);
    } catch (e) {
      Logs().e('ChatBloc: ошибка загрузки чатов', e);
      List<Chat> fallbackChats = state.chats;
      try {
        final cached = await getChatsUseCase.getCachedChats();
        if (cached.isNotEmpty) {
          fallbackChats = cached;
          Logs().d('ChatBloc: показаны кэшированные чаты (сервер недоступен)');
        }
      } catch (_) {}
      if (!silent) {
        emit(state.copyWith(
          isLoading: false,
          chats: sortChatsForList(fallbackChats),
          error: fallbackChats.isEmpty ? 'Ошибка загрузки чатов' : null,
        ));
      } else {
        emit(state.copyWith(isLoading: false, chats: sortChatsForList(fallbackChats)));
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
      emit(state.copyWith(isLoading: false, chats: sortChatsForList(chats), selectedChat: chat));
      await _loadMessagesForChat(chat, emit);
    } catch (e) {
      Logs().e('ChatBloc: ошибка открытия чата с пользователем', e);
      emit(state.copyWith(isLoading: false, error: 'Ошибка открытия чата'));
    }
  }

  Future<void> _onOpenGroupById(
    ChatOpenGroupById event,
    Emitter<ChatState> emit,
  ) async {
    Chat? chat;
    for (final c in state.chats) {
      if (c.isGroup && c.peerGroupId == event.groupId) {
        chat = c;
        break;
      }
    }

    if (chat == null) {
      emit(state.copyWith(isLoading: true, error: null));
      try {
        final list = await getChatsUseCase();
        final sorted = sortChatsForList(list);
        emit(state.copyWith(chats: sorted, isLoading: false));
        for (final c in sorted) {
          if (c.isGroup && c.peerGroupId == event.groupId) {
            chat = c;
            break;
          }
        }
      } catch (e) {
        Logs().e('ChatBloc: обновление чатов для группы', e);
        emit(
          state.copyWith(
            isLoading: false,
            error: 'Не удалось загрузить список чатов',
          ),
        );
        return;
      }
    }

    if (chat == null) {
      emit(
        state.copyWith(
          error: 'Группа не в списке чатов. После одобрения заявки обновите чаты.',
        ),
      );
      return;
    }

    add(ChatSelectChat(chat));
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
      emit(state.copyWith(isLoading: false, chats: sortChatsForList(chats), selectedChat: chat));
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
        clearTyping: true,
        clearReplyTo: true,
        clearGroupMentionMembers: true,
      ),
    );

    if (event.chat.isGroup) {
      unawaited(_fetchGroupMentionMembers(event.chat.peerGroupId));
    }

    if (event.chat.unreadCount > 0) {
      unawaited(
        clearUnreadChatUseCase(event.chat).catchError((Object _) {}),
      );
    }

    try {
      final cached = await getChatMessagesUseCase.getCachedMessages(
        event.chat.id,
        100,
      );
      if (cached.isNotEmpty) {
        emit(state.copyWith(messages: cached, isLoading: false));
      }
    } catch (_) {}
    unawaited(_loadAndEmitMessagesForChat(event.chat));
  }

  Future<void> _fetchGroupMentionMembers(int groupId) async {
    if (groupId <= 0) {
      return;
    }
    try {
      final members = await getGroupMentionMembersUseCase(groupId);
      add(
        ChatGroupMentionMembersLoaded(groupId: groupId, members: members),
      );
    } catch (e) {
      Logs().e('ChatBloc: не удалось загрузить участников для @', e);
    }
  }

  void _onGroupMentionMembersLoaded(
    ChatGroupMentionMembersLoaded event,
    Emitter<ChatState> emit,
  ) {
    if (state.selectedChat?.isGroup != true ||
        state.selectedChat!.peerGroupId != event.groupId) {
      return;
    }
    emit(state.copyWith(groupMentionMembers: event.members));
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
      try {
        messages = await getChatMessagesUseCase.getCachedMessages(chat.id, 100);
      } catch (_) {
        messages = state.messages;
      }
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

    final loadedIds = event.messages.map((m) => m.id).toSet();
    final fromStream = state.messages
      .where((m) => !loadedIds.contains(m.id))
      .toList();
    final merged = [...event.messages, ...fromStream]
      ..sort((a, b) => a.id.compareTo(b.id));
    emit(
      state.copyWith(
        messages: merged,
        chats: sortChatsForList(event.updatedChats),
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
          chats: sortChatsForList(updatedChats),
        ),
      );
      await _loadPendingQueueForChat(chat.id, emit);
    } catch (e) {
      Logs().e('ChatBloc: ошибка загрузки сообщений', e);
      List<Message> fallbackMessages = state.messages;
      if (fallbackMessages.isEmpty) {
        try {
          fallbackMessages = await getChatMessagesUseCase.getCachedMessages(
            chat.id,
            100,
          );
        } catch (_) {}
      }
      emit(state.copyWith(messages: fallbackMessages, isLoading: false));
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
      if (a.fileId != null && a.fileId!.isNotEmpty) {
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
          .where((a) => a.fileId != null && a.fileId!.isNotEmpty)
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
        mention: chat.isGroup ? event.mention : null,
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

  Future<void> _onSendSticker(
    ChatSendSticker event,
    Emitter<ChatState> emit,
  ) async {
    final chat = state.selectedChat;
    if (chat == null) {
      emit(state.copyWith(error: 'Чат не выбран'));
      return;
    }

    emit(state.copyWith(isSending: true, error: null));
    try {
      final replyToId = state.replyTo?.id ?? 0;
      final message = await sendChatStickerUseCase(
        peerUserId: chat.isGroup ? null : chat.peerUserId,
        peerGroupId: chat.isGroup ? chat.peerGroupId : null,
        stickerId: event.stickerId,
        replyToMessageId: replyToId,
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
      Logs().e('ChatBloc: ошибка отправки стикера', e);
      emit(
        state.copyWith(isSending: false, error: 'Ошибка отправки стикера'),
      );
    }
  }

  Future<void> _onSendCode(
    ChatSendCode event,
    Emitter<ChatState> emit,
  ) async {
    final chat = state.selectedChat;
    if (chat == null) {
      emit(state.copyWith(error: 'Чат не выбран'));
      return;
    }

    emit(state.copyWith(isSending: true, error: null));
    try {
      final replyToId = state.replyTo?.id ?? 0;
      final message = await sendChatCodeUseCase(
        lang: event.lang,
        code: event.code,
        peerUserId: chat.isGroup ? null : chat.peerUserId,
        peerGroupId: chat.isGroup ? chat.peerGroupId : null,
        replyToMessageId: replyToId,
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
      Logs().e('ChatBloc: ошибка отправки кода', e);
      emit(
        state.copyWith(isSending: false, error: 'Ошибка отправки кода'),
      );
    }
  }

  Future<void> _onSendLocation(
    ChatSendLocation event,
    Emitter<ChatState> emit,
  ) async {
    final chat = state.selectedChat;
    if (chat == null) {
      emit(state.copyWith(error: 'Чат не выбран'));
      return;
    }

    emit(state.copyWith(isSending: true, error: null));
    try {
      final replyToId = state.replyTo?.id ?? 0;
      final message = await sendChatLocationUseCase(
        latitude: event.latitude,
        longitude: event.longitude,
        description: event.description,
        peerUserId: chat.isGroup ? null : chat.peerUserId,
        peerGroupId: chat.isGroup ? chat.peerGroupId : null,
        replyToMessageId: replyToId,
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
      Logs().e('ChatBloc: ошибка отправки местоположения', e);
      emit(
        state.copyWith(
          isSending: false,
          error: 'Ошибка отправки местоположения',
        ),
      );
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

  void _onClearSnackbarHint(ChatClearSnackbarHint event, Emitter<ChatState> emit) {
    emit(state.copyWith(clearSnackbarHint: true));
  }

  Future<void> _onCollectStickerFromMessage(
    ChatCollectStickerFromMessage event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(error: null));
    try {
      await collectStickerFromMessageUseCase(event.messageId);
      emit(state.copyWith(snackbarHint: 'Стикер добавлен в коллекцию'));
    } on Failure catch (e) {
      emit(state.copyWith(error: e.message));
    } catch (e, st) {
      Logs().e('ChatBloc: collect sticker from message', e, st);
      emit(state.copyWith(error: 'Не удалось сохранить стикер'));
    }
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

  Future<void> _syncNotificationSettingsFromServer(List<Chat> chats) async {
    final settings = chatNotificationSettings;
    if (settings == null) return;
    await settings.ensureLoaded();
    for (final c in chats) {
      await settings.setMuted(c.id, c.notificationsMuted);
    }
  }

  Future<void> _onToggleChatNotifications(
    ChatToggleChatNotifications event,
    Emitter<ChatState> emit,
  ) async {
    final chat = event.chat;
    final settings = chatNotificationSettings;
    await settings?.ensureLoaded();

    final nextMuted = settings == null
        ? !chat.notificationsMuted
        : !settings.isMuted(chat.id);
    try {
      await setChatNotificationsUseCase(chat, nextMuted);
    } catch (_) {
      return;
    }

    await settings?.setMuted(chat.id, nextMuted);
    final updatedChat = chat.copyWith(notificationsMuted: nextMuted);
    final updatedChats = state.chats
        .map((c) => c.id == chat.id ? updatedChat : c)
        .toList();
    emit(state.copyWith(chats: sortChatsForList(updatedChats)));
  }

  Future<void> _onTogglePin(
    ChatTogglePin event,
    Emitter<ChatState> emit,
  ) async {
    final chat = event.chat;
    if (chat.listId <= 0) {
      emit(state.copyWith(error: 'Обновите список чатов'));
      return;
    }
    final wantPin = !chat.isPinned;
    if (wantPin) {
      final pinned = state.chats.where((c) => c.isPinned).length;
      if (pinned >= 4) {
        emit(state.copyWith(error: 'Не больше 4 закреплённых чатов'));
        return;
      }
    }
    try {
      await setChatPinUseCase(listId: chat.listId, pin: wantPin);
    } on Failure catch (e) {
      emit(state.copyWith(error: e.message));
      return;
    } catch (_) {
      emit(state.copyWith(error: 'Не удалось изменить закрепление'));
      return;
    }
    final updated = state.chats.map((c) {
      if (c.id != chat.id) {
        return c;
      }
      return c.copyWith(isPinned: wantPin);
    }).toList();
    Chat? sel = state.selectedChat;
    if (sel?.id == chat.id) {
      sel = sel!.copyWith(isPinned: wantPin);
    }
    emit(
      state.copyWith(
        chats: sortChatsForList(updated),
        selectedChat: sel,
      ),
    );
  }

  void _emitAfterGroupLeft(Emitter<ChatState> emit, int groupId) {
    final updated = state.chats
        .where((c) => !(c.isGroup && c.peerGroupId == groupId))
        .toList();
    final sel = state.selectedChat;
    final clearSel =
        sel != null && sel.isGroup && sel.peerGroupId == groupId;
    emit(
      state.copyWith(
        chats: sortChatsForList(updated),
        selectedChat: clearSel ? null : state.selectedChat,
        messages: clearSel ? const [] : state.messages,
      ),
    );
  }

  void _onGroupLeftApplied(
    ChatGroupLeftApplied event,
    Emitter<ChatState> emit,
  ) {
    _emitAfterGroupLeft(emit, event.groupId);
    unawaited(chatDraftLocal.removeForGroupId(event.groupId));
    add(const ChatLoadChats(silent: true));
  }

  Future<void> _onLeaveGroup(
    ChatLeaveGroup event,
    Emitter<ChatState> emit,
  ) async {
    final chat = event.chat;
    if (!chat.isGroup) {
      return;
    }
    try {
      await leaveGroupUseCase(chat.peerGroupId);
    } on Failure catch (e) {
      emit(state.copyWith(error: e.message));
      return;
    } catch (_) {
      emit(state.copyWith(error: 'Не удалось выйти из группы'));
      return;
    }
    _emitAfterGroupLeft(emit, chat.peerGroupId);
    unawaited(chatDraftLocal.removeForChat(chat));
    add(const ChatLoadChats(silent: true));
  }

  void _onNewMessageReceived(
    ChatNewMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final message = event.message;
    final selectedChat = state.selectedChat;
    final currentUserId = authBloc.state.user?.id ?? 0;
    if (currentUserId == 0) {
      return;
    }

    final isIncomingFromOther = message.fromPeerUserId != currentUserId;
    if (isIncomingFromOther) {
      final chatId = message.isGroupChat
          ? -message.peerGroupId
          : (message.peerUserId == currentUserId ? message.fromPeerUserId : message.peerUserId);

      if (chatNotificationSettings?.isMuted(chatId) != true) {
        notificationSoundService?.play();
      }
    }

    final isInOpenChat =
        selectedChat != null &&
        (selectedChat.isGroup
            ? message.isInGroupChat(selectedChat.peerGroupId.toString())
            : message.isInDialog(
                currentUserId,
                selectedChat.peerUserId,
              ));

    if (isInOpenChat) {
      if (state.messages.any((m) => m.id == message.id)) {
        return;
      }
      emit(state.copyWith(messages: [...state.messages, message]));
      Logs().d('ChatBloc: добавлено новое сообщение в чат');
      _loadPendingQueueForChat(selectedChat.id, emit);

      return;
    }

    int? chatIdToIncrement;
    if (message.isGroupChat) {
      chatIdToIncrement = -message.peerGroupId;
    } else {
      final otherUserId = message.peerUserId == currentUserId
          ? message.fromPeerUserId
          : message.peerUserId;
      chatIdToIncrement = otherUserId;
    }

    if (!state.chats.any((c) => c.id == chatIdToIncrement)) {
      return;
    }

    final updatedChats = state.chats.map((c) {
      if (c.id != chatIdToIncrement) {
        return c;
      }

      return c.copyWith(unreadCount: c.unreadCount + 1);
    }).toList();

    emit(state.copyWith(chats: sortChatsForList(updatedChats)));
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

  void _onMessagesDeletedFromServer(
    ChatMessagesDeletedFromServer event,
    Emitter<ChatState> emit,
  ) {
    final selectedChat = state.selectedChat;
    if (selectedChat == null) {
      return;
    }

    final currentUserId = authBloc.state.user?.id ?? 0;
    if (currentUserId == 0) {
      return;
    }

    if (selectedChat.isGroup) {
      return;
    }

    final otherUserId = selectedChat.peerUserId;

    final isThisDialog =
        (event.peerId == currentUserId && event.fromPeerId == otherUserId) ||
        (event.peerId == otherUserId && event.fromPeerId == currentUserId);
    if (!isThisDialog) {
      return;
    }

    final idSet = event.messageIds.toSet();
    final updatedMessages = state.messages
        .where((m) => !idSet.contains(m.id))
        .toList();
    final updatedSelection = state.selectedMessageIds.difference(idSet);
    emit(
      state.copyWith(
        messages: updatedMessages,
        selectedMessageIds: updatedSelection,
      ),
    );
    Logs().d('ChatBloc: удалены сообщения с сервера ids=$idSet');
  }

  void _onMessagesRead(ChatMessagesRead event, Emitter<ChatState> emit) {
    final currentUserId = authBloc.state.user?.id ?? 0;
    if (currentUserId == 0) {
      return;
    }

    if (event.peerUserId != currentUserId) {
      return;
    }

    final selectedChat = state.selectedChat;
    if (selectedChat == null) {
      return;
    }

    if (selectedChat.peerUserId != event.readerUserId) {
      return;
    }

    final updatedMessages = state.messages.map((m) {
      if (m.senderId == currentUserId &&
          m.id <= event.lastReadMessageId &&
          !m.isRead) {
        return m.copyWith(isRead: true);
      }

      return m;
    }).toList();

    emit(state.copyWith(messages: updatedMessages));
    Logs().d('ChatBloc: сообщения прочитаны до id=${event.lastReadMessageId}');
  }

  void _onUserTyping(ChatUserTyping event, Emitter<ChatState> emit) {
    _typingClearTimer?.cancel();
    emit(state.copyWith(typing: event.payload));
    _typingClearTimer = Timer(const Duration(seconds: 5), () {
      add(ChatClearTyping(event.payload));
    });
  }

  void _onClearTyping(ChatClearTyping event, Emitter<ChatState> emit) {
    final cur = state.typing;
    if (cur != null && cur == event.payload) {
      emit(state.copyWith(clearTyping: true));
    }
  }

  void _onSendTyping(ChatSendTyping event, Emitter<ChatState> emit) {
    final chat = state.selectedChat;
    if (chat == null) {
      return;
    }

    if (chat.isGroup) {
      sendChatTypingUseCase(peerGroupId: chat.peerGroupId);
      return;
    }

    sendChatTypingUseCase(peerUserId: chat.peerUserId);
  }

  Future<void> _onInlineCallbackPressed(
    ChatInlineCallbackPressed event,
    Emitter<ChatState> emit,
  ) async {
    final chat = state.selectedChat;
    if (chat == null) {
      return;
    }

    try {
      await reportInlineCallbackUseCase(
        chat: chat,
        messageId: event.messageId,
        callbackData: event.callbackData,
      );
    } on Failure catch (e) {
      emit(state.copyWith(error: e.message));
    } catch (_) {
      emit(state.copyWith(error: 'Не удалось отправить нажатие кнопки'));
    }
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

  Future<void> _onSyncRestored(
    ChatSyncRestored event,
    Emitter<ChatState> emit,
  ) async {
    final chat = state.selectedChat;
    if (chat == null) {
      return;
    }
    Logs().d('ChatBloc: соединение восстановлено, перезагрузка сообщений чата ${chat.id}');
    await _loadMessagesForChat(chat, emit);
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
      final hasOlder = await getChatMessagesUseCase.hasOlderCachedMessages(
        chat.id,
        oldestId,
      );
      List<Message> older;
      if (hasOlder) {
        older = await getChatMessagesUseCase.getCachedMessages(
          chat.id,
          50,
          beforeMessageId: oldestId,
        );
      } else {
      final peerUserId = chat.isGroup ? null : chat.peerUserId;
      final peerGroupId = chat.isGroup ? chat.peerGroupId : null;
      older = await getChatMessagesUseCase(
          peerUserId: peerUserId,
          peerGroupId: peerGroupId,
          messageId: oldestId,
          limit: 50,
        );
      }

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
        chats: sortChatsForList(updatedChats),
        selectedChat: isDeletingSelected ? null : state.selectedChat,
        messages: isDeletingSelected ? const [] : state.messages,
      ));
      unawaited(chatDraftLocal.removeForChat(event.chat));
    } catch (e) {
      Logs().e('ChatBloc: ошибка удаления чата', e);
      emit(state.copyWith(error: 'Ошибка удаления чата'));
    }
  }
}
