import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/layout/responsive.dart';
import 'package:voosu/core/snackbar_ext.dart';
import 'package:voosu/domain/entities/user.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/core/file_stream.dart';
import 'package:voosu/domain/entities/attachment_upload.dart';
import 'package:voosu/domain/repositories/account_repository.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_event.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_state.dart';
import 'package:voosu/domain/usecases/chat/upload_chat_file_usecase.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_widgets.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class UserChatScreen extends StatefulWidget {
  const UserChatScreen({super.key});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  late final TextEditingController _messageController;
  final _scrollController = ScrollController();
  bool _showUserSearch = false;
  bool _loadMoreTriggered = false;

  static const double _loadMoreScrollThreshold = 120;

  @override
  void initState() {
    super.initState();
    _messageController = EmojiTextEditingController(
      emojiTextStyle: const TextStyle(fontSize: 16),
    );
    _scrollController.addListener(_onScrollForLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatBloc>().add(const ChatStarted());
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

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollForLoadMore);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSendMessage(String text, {List<AttachmentUpload>? attachments}) {
    context.read<ChatBloc>().add(
      ChatSendMessage(text, attachments: attachments),
    );
  }

  Future<int?> _uploadLargeFile(
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

  Future<int?> _uploadFile(
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

  Future<void> _onDownloadAttachment(int fileId, String filename) async {
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
      final bytes = await di.sl<AccountRepository>().getFile(fileId);
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

  void _onSearchUserSelected(User user) {
    context.read<ChatBloc>().add(ChatOpenWithUser(user.id));
    setState(() => _showUserSearch = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state.error != null) {
          context.showErrorSnackBar(state.error!);
          context.read<ChatBloc>().add(const ChatClearError());
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
                : ChatListWidget(state: state)
              : Column(
                children: [
                  ChatContentHeader(
                    selectedChat: selectedChat,
                    chatState: state,
                    currentUserId:  context.read<AuthBloc>().state.user?.id ?? 0,
                    showBackButton: true,
                  ),
                  Expanded(
                    child: ChatMessagesList(
                      state: state,
                      scrollController: _scrollController,
                      onDownloadAttachment: _onDownloadAttachment,
                    ),
                  ),
                  if (!state.isSelectionMode)
                    ChatInputBar(
                      controller: _messageController,
                      onSendMessage: _onSendMessage,
                      isEnabled: !state.isSending,
                      isSending: state.isSending,
                      uploadFile: _uploadFile,
                      uploadLargeFile: _uploadLargeFile,
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
                    ),
                    Expanded(
                      child: _showUserSearch
                        ? ChatUserSearchPanel(
                          onUserSelected: _onSearchUserSelected,
                          onClose: _closeUserSearch,
                        )
                        : ChatListWidget(state: state),
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
                        currentUserId: context.read<AuthBloc>().state.user?.id ?? 0,
                        showBackButton: false,
                      ),
                      Expanded(
                        child: ChatMessagesList(
                          state: state,
                          scrollController: _scrollController,
                          onDownloadAttachment: _onDownloadAttachment,
                        ),
                      ),
                      if (selectedChat != null && !state.isSelectionMode)
                        ChatInputBar(
                          controller: _messageController,
                          onSendMessage: _onSendMessage,
                          isEnabled: !state.isSending,
                          isSending: state.isSending,
                          uploadFile: _uploadFile,
                          uploadLargeFile: _uploadLargeFile,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatListPanelHeader extends StatelessWidget {
  final bool isSearchMode;
  final VoidCallback onSearch;
  final VoidCallback onCloseSearch;

  const _ChatListPanelHeader({
    required this.isSearchMode,
    required this.onSearch,
    required this.onCloseSearch,
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
