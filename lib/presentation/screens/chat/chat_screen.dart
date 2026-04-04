import 'dart:async';
import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/layout/responsive.dart';
import 'package:voosu/core/snackbar_ext.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/user.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/core/file_stream.dart';
import 'package:voosu/domain/entities/attachment_upload.dart';
import 'package:voosu/domain/entities/group_message_mention.dart';
import 'package:voosu/data/data_sources/local/chat_draft_local_data_source.dart';
import 'package:voosu/data/services/media_cache_service.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_event.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_state.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/entities/user_sticker.dart';
import 'package:voosu/domain/usecases/chat/add_sticker_from_uploaded_file_usecase.dart';
import 'package:voosu/domain/usecases/chat/delete_my_stickers_usecase.dart';
import 'package:voosu/domain/usecases/chat/list_my_stickers_usecase.dart';
import 'package:voosu/domain/usecases/chat/upload_chat_file_usecase.dart';
import 'package:voosu/presentation/screens/chat/create_group_chat_screen.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_widgets.dart';
import 'package:voosu/presentation/screens/chat/widgets/forward_to_chat_dialog.dart';
import 'package:voosu/presentation/screens/chat/widgets/create_poll_dialog.dart';
import 'package:voosu/presentation/screens/chat/widgets/send_special_message_dialogs.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class UserChatScreen extends StatefulWidget {
  const UserChatScreen({super.key});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  late final TextEditingController _messageController;
  late final TextEditingController _chatListFilterController;
  final _scrollController = ScrollController();
  bool _showUserSearch = false;
  Timer? _typingDebounce;
  Timer? _draftSaveDebounce;
  Chat? _draftChat;
  bool _loadMoreTriggered = false;

  static const double _loadMoreScrollThreshold = 120;

  @override
  void initState() {
    super.initState();
    _messageController = EmojiTextEditingController(
      emojiTextStyle: const TextStyle(fontSize: 16),
    );
    _chatListFilterController = TextEditingController();
    _messageController.addListener(_debouncedSendTyping);
    _scrollController.addListener(_onScrollForLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<ChatBloc>().add(const ChatStarted());
      _bootstrapChatDrafts(context);
    });
  }

  void _bootstrapChatDrafts(BuildContext context) {
    final sel = context.read<ChatBloc>().state.selectedChat;
    _draftChat = sel;
    if (sel != null) {
      final d = di.sl<ChatDraftLocalDataSource>().peekForChat(sel);
      if (d != null && d.isNotEmpty) {
        _messageController.value = TextEditingValue(
          text: d,
          selection: TextSelection.collapsed(offset: d.length),
        );
      }
    }
    _messageController.addListener(_scheduleDraftSave);
  }

  void _scheduleDraftSave() {
    final chat = _draftChat;
    if (chat == null) {
      return;
    }
    _draftSaveDebounce?.cancel();
    _draftSaveDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) {
        return;
      }
      final c = _draftChat;
      if (c == null) {
        return;
      }
      unawaited(
        di.sl<ChatDraftLocalDataSource>().save(c, _messageController.text),
      );
    });
  }

  void _onScrollForLoadMore() {
    if (!_scrollController.hasClients) {
      return;
    }

    final pos = _scrollController.position;
    if (pos.pixels <= _loadMoreScrollThreshold &&
        pos.minScrollExtent != pos.maxScrollExtent) {
      if (!_loadMoreTriggered) {
        _loadMoreTriggered = true;
        context.read<ChatBloc>().add(const ChatLoadMoreMessages());
      }
    } else {
      _loadMoreTriggered = false;
    }
  }

  void _debouncedSendTyping() {
    _typingDebounce?.cancel();
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    _typingDebounce = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        context.read<ChatBloc>().add(const ChatSendTyping());
      }
    });
  }

  @override
  void dispose() {
    _draftSaveDebounce?.cancel();
    _typingDebounce?.cancel();
    _messageController.removeListener(_scheduleDraftSave);
    _messageController.removeListener(_debouncedSendTyping);
    final c = _draftChat;
    if (c != null) {
      unawaited(
        di.sl<ChatDraftLocalDataSource>().save(c, _messageController.text),
      );
    }
    _scrollController.removeListener(_onScrollForLoadMore);
    _messageController.dispose();
    _chatListFilterController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _chatListFilterField() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: _chatListFilterController,
        textInputAction: TextInputAction.search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Поиск чатов',
          prefixIcon: const Icon(Icons.search_rounded, size: 22),
          isDense: true,
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildChatListPanel(ChatState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chatListFilterField(),
        Expanded(
          child: ChatListWidget(
            state: state,
            listFilter: _chatListFilterController.text,
          ),
        ),
      ],
    );
  }

  void _onSendMessage(
    String text, {
    List<AttachmentUpload>? attachments,
    GroupMessageMention? mention,
  }) {
    context.read<ChatBloc>().add(
      ChatSendMessage(text, attachments: attachments, mention: mention),
    );
  }

  Future<String?> _uploadLargeFile(
    String path,
    String filename,
    int size, [
    void Function(int sentBytes, int? totalBytes)? onProgress,
  ]) async {
    try {
      final chat = context.read<ChatBloc>().state.selectedChat;
      if (chat == null) {
        return null;
      }

      final stream = streamFromPath(path, size);
      return await di.sl<UploadChatFileUseCase>().call(
        filename: filename,
        chunkStream: stream,
        totalBytes: size,
        onProgress: onProgress,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _uploadFile(
    String filename,
    Stream<List<int>> chunkStream,
    int totalBytes, [
    void Function(int sentBytes, int? totalBytes)? onProgress,
  ]) async {
    try {
      final chat = context.read<ChatBloc>().state.selectedChat;
      if (chat == null) {
        return null;
      }

      return await di.sl<UploadChatFileUseCase>().call(
        filename: filename,
        chunkStream: chunkStream,
        totalBytes: totalBytes,
        onProgress: onProgress,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _onDownloadAttachment(String fileId, String filename) async {
    final safeName = filename.split(RegExp(r'[/\\]')).last;
    if (safeName.isEmpty) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Скачивание...'),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      final bytes = await di.sl<MediaCacheService>().getFile(fileId);
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$safeName');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
      if (!mounted) {
        return;
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось загрузить вложение')),
        );
      }
    }
  }

  Future<List<int>?> _onLoadAttachmentContent(String fileId) async {
    try {
      return await di.sl<MediaCacheService>().getFile(fileId);
    } catch (_) {
      return null;
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    final target = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _openUserSearch() {
    setState(() => _showUserSearch = true);
  }

  void _closeUserSearch() {
    setState(() => _showUserSearch = false);
  }

  void _openCreateGroup() {
    final chatBloc = context.read<ChatBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BlocProvider.value(
          value: chatBloc,
          child: const CreateGroupChatScreen(),
        ),
      ),
    );
  }

  void _onSearchUserSelected(User user) {
    context.read<ChatBloc>().add(ChatOpenWithUser(user.id));
    setState(() => _showUserSearch = false);
  }

  void _onSystemMessageUserTap(int userId) {
    if (userId <= 0) {
      return;
    }
    context.read<ChatBloc>().add(ChatOpenWithUser(userId));
  }

  void _onReplyToMessage(Message message) {
    context.read<ChatBloc>().add(ChatReplyToMessage(message));
  }

  Future<void> _onForwardMessage(Message message) async {
    final state = context.read<ChatBloc>().state;
    final selectedChat = state.selectedChat;
    final targetChat = await showForwardToChatDialog(
      context: context,
      chats: state.chats,
      currentChat: selectedChat,
    );
    if (!mounted || targetChat == null) {
      return;
    }

    context.read<ChatBloc>().add(ChatForwardMessageToChat(message, targetChat));
  }

  void _onInlineButtonPressed(int messageId, String callbackData) {
    if (!mounted) {
      return;
    }

    context.read<ChatBloc>().add(
      ChatInlineCallbackPressed(messageId, callbackData),
    );
  }

  void _onVotePoll(int messageId, int optionId) {
    if (!mounted) {
      return;
    }

    context.read<ChatBloc>().add(ChatVotePoll(messageId, optionId));
  }

  Future<void> _openCreatePoll() async {
    if (!mounted) {
      return;
    }

    final result = await CreatePollDialog.show(context);
    if (!mounted || result == null) {
      return;
    }

    context.read<ChatBloc>().add(
      ChatCreatePoll(
        question: result.question,
        options: result.options,
        anonymous: result.anonymous,
      ),
    );
  }

  Future<void> _openSendCode() async {
    if (!mounted) {
      return;
    }

    final result = await SendSpecialMessageDialogs.pickCode(context);
    if (!mounted || result == null) {
      return;
    }

    context.read<ChatBloc>().add(
      ChatSendCode(lang: result.lang, code: result.code),
    );
  }

  Future<void> _openSendLocation() async {
    if (!mounted) {
      return;
    }

    final result = await SendSpecialMessageDialogs.pickLocation(context);
    if (!mounted || result == null) {
      return;
    }

    context.read<ChatBloc>().add(
      ChatSendLocation(
        latitude: result.lat,
        longitude: result.lon,
        description: result.desc,
      ),
    );
  }

  Future<void> _openStickerPicker() async {
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ChatStickerPickerSheet(
        onStickerSelected: (id) {
          if (mounted) {
            context.read<ChatBloc>().add(ChatSendSticker(id));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listenWhen: (p, c) => p.selectedChat?.id != c.selectedChat?.id,
      listener: (context, state) {
        final drafts = di.sl<ChatDraftLocalDataSource>();
        final prev = _draftChat;
        _draftSaveDebounce?.cancel();
        if (prev != null) {
          final stillInList = state.chats.any((c) => c.id == prev.id);
          if (stillInList) {
            unawaited(drafts.save(prev, _messageController.text));
          } else {
            unawaited(drafts.removeForChat(prev));
          }
        }
        _draftChat = state.selectedChat;
        if (state.selectedChat != null) {
          final d = drafts.peekForChat(state.selectedChat!) ?? '';
          _messageController.value = TextEditingValue(
            text: d,
            selection: TextSelection.collapsed(offset: d.length),
          );
        } else {
          _messageController.clear();
        }
      },
      child: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state.error != null) {
            context.showErrorSnackBar(state.error!);
            context.read<ChatBloc>().add(const ChatClearError());
          }
          if (state.snackbarHint != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.snackbarHint!)),
            );
            context.read<ChatBloc>().add(const ChatClearSnackbarHint());
          }
          if (state.messages.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _scrollToBottom(),
            );
          }
        },
        builder: (context, state) {
          final isMobile = Breakpoints.isMobile(context);
          final selectedChat = state.selectedChat;

          if (isMobile) {
            return Scaffold(
              appBar: selectedChat == null
                  ? AppBar(
                      title: Text(
                        _showUserSearch ? 'Найти пользователя' : 'Чаты',
                      ),
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      leading: _showUserSearch
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back_rounded),
                              onPressed: _closeUserSearch,
                            )
                          : null,
                      actions: _showUserSearch
                          ? null
                          : [
                              IconButton(
                                icon: const Icon(Icons.group_add_rounded),
                                tooltip: 'Новый групповой чат',
                                onPressed: _openCreateGroup,
                              ),
                              IconButton(
                                icon: const Icon(Icons.person_search_rounded),
                                tooltip: 'Найти пользователя',
                                onPressed: _openUserSearch,
                              ),
                            ],
                    )
                  : null,
              body: selectedChat == null
                  ? _showUserSearch
                        ? ChatUserSearchPanel(
                            onUserSelected: _onSearchUserSelected,
                            onClose: _closeUserSearch,
                          )
                        : _buildChatListPanel(state)
                  : Column(
                      children: [
                        ChatContentHeader(
                          selectedChat: selectedChat,
                          chatState: state,
                          currentUserId:
                              context.read<AuthBloc>().state.user?.id ?? 0,
                          showBackButton: true,
                        ),
                        Expanded(
                          child: ChatMessagesList(
                            state: state,
                            scrollController: _scrollController,
                            onReply: _onReplyToMessage,
                            onForward: _onForwardMessage,
                            onInlineButtonPressed: _onInlineButtonPressed,
                            onVotePoll: _onVotePoll,
                            onDownloadAttachment: _onDownloadAttachment,
                            onLoadAttachmentContent: _onLoadAttachmentContent,
                            onLoadMixedImageBytes: _onLoadAttachmentContent,
                            onSystemMessageUserTap: _onSystemMessageUserTap,
                            onCollectStickerFromMessage: (id) => context
                                .read<ChatBloc>()
                                .add(ChatCollectStickerFromMessage(id)),
                          ),
                        ),
                        if (!state.isSelectionMode)
                          ChatInputBar(
                            controller: _messageController,
                            onSendMessage: _onSendMessage,
                            isEnabled: !state.isSending,
                            isSending: state.isSending,
                            replyTo: state.replyTo,
                            onClearReply: () => context.read<ChatBloc>().add(
                              const ChatClearReply(),
                            ),
                            uploadFile: _uploadFile,
                            uploadLargeFile: _uploadLargeFile,
                            onCreatePoll: state.selectedChat?.isGroup == true
                                ? _openCreatePoll
                                : null,
                            onStickers: _openStickerPicker,
                            onSendCode: _openSendCode,
                            onSendLocation: _openSendLocation,
                            mentionMembers: selectedChat.isGroup
                                ? state.groupMentionMembers
                                : const [],
                          ),
                      ],
                    ),
            );
          }

        return Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ChatListPanelHeader(
                        isSearchMode: _showUserSearch,
                        onSearch: _openUserSearch,
                        onCloseSearch: _closeUserSearch,
                        onCreateGroup: _openCreateGroup,
                      ),
                      Expanded(
                        child: _showUserSearch
                            ? ChatUserSearchPanel(
                                onUserSelected: _onSearchUserSelected,
                                onClose: _closeUserSearch,
                              )
                            : _buildChatListPanel(state),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLowest.withValues(alpha: 0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ChatContentHeader(
                          selectedChat: selectedChat,
                          chatState: state,
                          currentUserId:
                              context.read<AuthBloc>().state.user?.id ?? 0,
                          showBackButton: false,
                        ),
                        Expanded(
                          child: ChatMessagesList(
                            state: state,
                            scrollController: _scrollController,
                            onReply: _onReplyToMessage,
                            onForward: _onForwardMessage,
                            onInlineButtonPressed: _onInlineButtonPressed,
                            onVotePoll: _onVotePoll,
                            onDownloadAttachment: _onDownloadAttachment,
                            onLoadAttachmentContent: _onLoadAttachmentContent,
                            onLoadMixedImageBytes: _onLoadAttachmentContent,
                            onSystemMessageUserTap: _onSystemMessageUserTap,
                            onCollectStickerFromMessage: (id) => context
                                .read<ChatBloc>()
                                .add(ChatCollectStickerFromMessage(id)),
                          ),
                        ),
                        if (selectedChat != null && !state.isSelectionMode)
                          ChatInputBar(
                            controller: _messageController,
                            onSendMessage: _onSendMessage,
                            isEnabled: !state.isSending,
                            isSending: state.isSending,
                            replyTo: state.replyTo,
                            onClearReply: () => context.read<ChatBloc>().add(
                              const ChatClearReply(),
                            ),
                            uploadFile: _uploadFile,
                            uploadLargeFile: _uploadLargeFile,
                            onCreatePoll: selectedChat.isGroup
                                ? _openCreatePoll
                                : null,
                            onStickers: _openStickerPicker,
                            onSendCode: _openSendCode,
                            onSendLocation: _openSendLocation,
                            mentionMembers: selectedChat.isGroup
                                ? state.groupMentionMembers
                                : const [],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChatStickerPickerSheet extends StatefulWidget {
  final void Function(int stickerId) onStickerSelected;

  const _ChatStickerPickerSheet({required this.onStickerSelected});

  @override
  State<_ChatStickerPickerSheet> createState() =>
      _ChatStickerPickerSheetState();
}

class _ChatStickerPickerSheetState extends State<_ChatStickerPickerSheet> {
  List<UserSticker>? _stickers;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await di.sl<ListMyStickersUseCase>()();
      if (!mounted) {
        return;
      }
      setState(() {
        _stickers = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Не удалось загрузить стикеры';
        _loading = false;
      });
    }
  }

  Future<void> _pickAndAdd() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }
    final f = result.files.single;
    List<int>? bytes = f.bytes;
    final name = f.name.isNotEmpty ? f.name : 'sticker.png';
    if ((bytes == null || bytes.isEmpty) && f.path != null) {
      try {
        bytes = await File(f.path!).readAsBytes();
      } catch (_) {
        bytes = null;
      }
    }
    if (bytes == null || bytes.isEmpty) {
      return;
    }

    try {
      final fileId = await di.sl<UploadChatFileUseCase>().call(
        filename: name,
        chunkStream: Stream.value(bytes),
        totalBytes: bytes.length,
      );
      await di.sl<AddStickerFromUploadedFileUseCase>().call(fileId);
      if (mounted) {
        await _reload();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось добавить стикер')),
        );
      }
    }
  }

  Future<void> _confirmDelete(UserSticker s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить стикер?'),
        content: const Text('Его нельзя будет восстановить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    try {
      await di.sl<DeleteMyStickersUseCase>().call([s.id]);
      if (mounted) {
        await _reload();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось удалить стикер')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Стикеры',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  tooltip: 'Добавить изображение',
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  onPressed: _pickAndAdd,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SizedBox(
                height: 220,
                child: Center(child: Text(_error!)),
              )
            else if (_stickers!.isEmpty)
              SizedBox(
                height: 220,
                child: Center(
                  child: Text(
                    'Нет стикеров.\nНажмите + чтобы добавить изображение.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              SizedBox(
                height: 300,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _stickers!.length,
                  itemBuilder: (context, i) {
                    final s = _stickers![i];
                    return Material(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onStickerSelected(s.id);
                        },
                        onLongPress: () => unawaited(_confirmDelete(s)),
                        borderRadius: BorderRadius.circular(10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            s.url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatListPanelHeader extends StatelessWidget {
  final bool isSearchMode;
  final VoidCallback onSearch;
  final VoidCallback onCloseSearch;
  final VoidCallback? onCreateGroup;

  const _ChatListPanelHeader({
    required this.isSearchMode,
    required this.onSearch,
    required this.onCloseSearch,
    this.onCreateGroup,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 4,
        right: 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          if (isSearchMode)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'К списку чатов',
              onPressed: onCloseSearch,
            ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              isSearchMode ? 'Найти пользователя' : 'Чаты',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
          const Spacer(),
          if (!isSearchMode) ...[
            if (onCreateGroup != null)
              IconButton(
                icon: const Icon(Icons.group_add_rounded),
                tooltip: 'Новый групповой чат',
                onPressed: onCreateGroup,
              ),
            IconButton(
              icon: const Icon(Icons.person_search_rounded),
              tooltip: 'Найти пользователя',
              onPressed: onSearch,
            ),
          ],
        ],
      ),
    );
  }
}
