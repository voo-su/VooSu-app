import 'package:flutter/material.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/core/layout/responsive.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/entities/pending_queue_item.dart';
import 'package:voosu/domain/entities/user.dart';
import 'package:voosu/domain/usecases/chat/clear_chat_history_usecase.dart';
import 'package:voosu/domain/usecases/chat/create_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/delete_chat_messages_usecase.dart';
import 'package:voosu/domain/usecases/chat/delete_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/get_chat_messages_usecase.dart';
import 'package:voosu/domain/usecases/chat/get_chats_usecase.dart';
import 'package:voosu/domain/usecases/chat/get_pending_for_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/remove_pending_message_usecase.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_widgets.dart';

class UserChatScreen extends StatefulWidget {
  const UserChatScreen({super.key});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final _scrollController = ScrollController();
  bool _showUserSearch = false;
  bool _loadMoreTriggered = false;

  late final GetChatsUseCase _getChatsUseCase = di.sl();
  late final CreateChatUseCase _createChatUseCase = di.sl();
  late final GetChatMessagesUseCase _getChatMessagesUseCase = di.sl();
  late final GetPendingForChatUseCase _getPendingForChatUseCase = di.sl();
  late final RemovePendingMessageUseCase _removePendingMessageUseCase = di.sl();
  late final DeleteChatMessagesUseCase _deleteChatMessagesUseCase = di.sl();
  late final ClearChatHistoryUseCase _clearChatHistoryUseCase = di.sl();
  late final DeleteChatUseCase _deleteChatUseCase = di.sl();

  List<Chat> _chats = [];
  Chat? _selectedChat;
  List<Message> _messages = [];
  List<PendingQueueItem> _pendingQueue = [];
  Set<int> _selectedMessageIds = {};
  bool _isLoading = false;
  bool _isLoadingMore = false;

  static const int _currentUserId = 0;

  static const double _loadMoreScrollThreshold = 120;

  bool get _isSelectionMode => _selectedMessageIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollForLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChats());
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _loadChats({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    try {
      final chats = await _getChatsUseCase();
      if (!mounted) {
        return;
      }
      setState(() {
        _chats = chats;
        if (!silent) {
          _isLoading = false;
        }
      });
    } catch (e) {
      Logs().e('UserChatScreen: ошибка загрузки чатов', e);
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reloadChatsSilent() async {
    try {
      final chats = await _getChatsUseCase();
      if (mounted) {
        setState(() => _chats = chats);
      }
    } catch (e) {
      Logs().e('UserChatScreen: ошибка тихой перезагрузки чатов', e);
    }
  }

  Future<void> _openWithUser(int userId) async {
    setState(() => _isLoading = true);
    try {
      final chat = await _createChatUseCase(userId);
      final chats = await _getChatsUseCase();
      if (!mounted) {
        return;
      }
      setState(() {
        _chats = chats;
        _selectedChat = chat;
        _messages = [];
        _pendingQueue = [];
        _selectedMessageIds = {};
        _isLoading = true;
      });
      await _loadMessagesAfterOpen(chat);
    } catch (e) {
      Logs().e('UserChatScreen: ошибка открытия чата с пользователем', e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMessagesAfterOpen(Chat chat) async {
    final id = chat.id;
    try {
      final messages = await _getChatMessagesUseCase(
        peerUserId: chat.peerUserId,
        messageId: 0,
        limit: 100,
      );
      final updatedChats = _chats
          .map((c) => c.id == chat.id ? c.copyWith(unreadCount: 0) : c)
          .toList();
      if (!mounted || _selectedChat?.id != id) {
        return;
      }
      final sorted = List<Message>.from(messages)
        ..sort((a, b) => a.id.compareTo(b.id));
      setState(() {
        _messages = sorted;
        _chats = updatedChats;
        _isLoading = false;
      });
      await _refreshPendingQueue(chat.id);
      if (mounted && _messages.isNotEmpty) {
        _scheduleScrollToBottom();
      }
    } catch (e) {
      Logs().e('UserChatScreen: ошибка загрузки сообщений', e);
      if (!mounted || _selectedChat?.id != id) {
        return;
      }
      setState(() => _isLoading = false);
      await _refreshPendingQueue(chat.id);
    }
  }

  void _selectChat(Chat chat) {
    setState(() {
      _selectedChat = chat;
      _messages = [];
      _pendingQueue = [];
      _isLoading = true;
      _selectedMessageIds = {};
    });
    _loadAndEmitMessagesForChat(chat);
  }

  Future<void> _loadAndEmitMessagesForChat(Chat chat) async {
    final id = chat.id;
    List<Message> messages;
    List<Chat> updatedChats;
    List<PendingQueueItem> pendingQueue = const [];
    try {
      messages = await _getChatMessagesUseCase(
        peerUserId: chat.peerUserId,
        messageId: 0,
        limit: 100,
      );
      updatedChats = _chats
          .map((c) => c.id == chat.id ? c.copyWith(unreadCount: 0) : c)
          .toList();
      pendingQueue = await _getPendingForChatUseCase(chat.id);
    } catch (e) {
      Logs().e('UserChatScreen: ошибка загрузки сообщений', e);
      messages = _messages;
      updatedChats = _chats;
    }
    if (!mounted || _selectedChat?.id != id) {
      return;
    }
    final merged = List<Message>.from(messages)
      ..sort((a, b) => a.id.compareTo(b.id));
    setState(() {
      _messages = merged;
      _chats = updatedChats;
      _pendingQueue = pendingQueue;
      _isLoading = false;
    });
    if (merged.isNotEmpty) {
      _scheduleScrollToBottom();
    }
  }

  Future<void> _refreshPendingQueue(int chatId) async {
    try {
      final queue = await _getPendingForChatUseCase(chatId);
      if (!mounted || _selectedChat?.id != chatId) {
        return;
      }
      setState(() => _pendingQueue = queue);
    } catch (_) {}
  }

  void _backToList() {
    setState(() {
      _selectedChat = null;
      _selectedMessageIds = {};
    });
  }

  void _clearSelection() {
    setState(() => _selectedMessageIds = {});
  }

  void _selectAllMyMessages() {
    final currentUserId = _currentUserId;
    final myIds = _messages
        .where((m) => m.senderId == currentUserId)
        .map((m) => m.id)
        .toSet();
    setState(() => _selectedMessageIds = myIds);
  }

  Future<void> _deleteMessage(Message message, bool forEveryone) async {
    final chat = _selectedChat;
    if (chat == null) {
      return;
    }
    try {
      await _deleteChatMessagesUseCase([message.id], forEveryone: forEveryone);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = _messages.where((m) => m.id != message.id).toList();
      });
      await _reloadChatsSilent();
    } catch (e) {
      Logs().e('UserChatScreen: ошибка удаления сообщения', e);
    }
  }

  Future<void> _deleteSelectedMessages(bool forEveryone) async {
    if (_selectedMessageIds.isEmpty) {
      return;
    }
    final ids = _selectedMessageIds.toList();
    try {
      await _deleteChatMessagesUseCase(ids, forEveryone: forEveryone);
      if (!mounted) {
        return;
      }
      final idSet = Set<int>.from(_selectedMessageIds);
      setState(() {
        _messages = _messages.where((m) => !idSet.contains(m.id)).toList();
        _selectedMessageIds = {};
      });
      await _reloadChatsSilent();
    } catch (e) {
      Logs().e('UserChatScreen: ошибка удаления сообщений', e);
    }
  }

  void _toggleMessageSelection(Message message) {
    final id = message.id;
    final next = Set<int>.from(_selectedMessageIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    setState(() => _selectedMessageIds = next);
  }

  Future<void> _loadMoreMessages() async {
    final chat = _selectedChat;
    if (chat == null || _messages.isEmpty || _isLoadingMore) {
      return;
    }

    final oldestId =
        _messages.map((m) => m.id).reduce((a, b) => a < b ? a : b);

    setState(() => _isLoadingMore = true);
    try {
      final older = await _getChatMessagesUseCase(
        peerUserId: chat.peerUserId,
        messageId: oldestId,
        limit: 50,
      );

      if (!mounted) {
        return;
      }
      if (older.isEmpty) {
        setState(() => _isLoadingMore = false);
        return;
      }

      setState(() {
        _messages = [...older, ..._messages];
        _isLoadingMore = false;
      });
    } catch (e) {
      Logs().e('UserChatScreen: ошибка подгрузки сообщений', e);
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _clearHistory() async {
    final chat = _selectedChat;
    if (chat == null) {
      return;
    }
    try {
      await _clearChatHistoryUseCase(peerUserId: chat.peerUserId);
      if (!mounted) {
        return;
      }
      setState(() => _messages = []);
      await _reloadChatsSilent();
    } catch (e) {
      Logs().e('UserChatScreen: ошибка очистки истории', e);
    }
  }

  Future<void> _deleteChat(Chat chat) async {
    try {
      await _deleteChatUseCase(peerUserId: chat.peerUserId);
      if (!mounted) {
        return;
      }
      final isDeletingSelected = _selectedChat?.id == chat.id;
      setState(() {
        _chats = _chats.where((c) => c.id != chat.id).toList();
        if (isDeletingSelected) {
          _selectedChat = null;
          _messages = [];
          _pendingQueue = [];
          _selectedMessageIds = {};
        }
      });
    } catch (e) {
      Logs().e('UserChatScreen: ошибка удаления чата', e);
    }
  }

  Future<void> _cancelPendingFromQueue(String localId) async {
    try {
      await _removePendingMessageUseCase(localId);
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingQueue =
            _pendingQueue.where((q) => q.localId != localId).toList();
      });
    } catch (_) {}
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
        _loadMoreMessages();
      }
    } else {
      _loadMoreTriggered = false;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollForLoadMore);
    _scrollController.dispose();
    super.dispose();
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
    _openWithUser(user.id);
    setState(() => _showUserSearch = false);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final selectedChat = _selectedChat;
    final currentUserId = _currentUserId;

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
                : ChatListWidget(
                    chats: _chats,
                    selectedChat: _selectedChat,
                    isLoading: _isLoading,
                    onSelectChat: _selectChat,
                    onDeleteChat: _deleteChat,
                  )
            : Column(
                children: [
                  ChatContentHeader(
                    selectedChat: selectedChat,
                    messages: _messages,
                    selectedMessageIds: _selectedMessageIds,
                    isSelectionMode: _isSelectionMode,
                    currentUserId: currentUserId,
                    showBackButton: true,
                    onBack: _backToList,
                    onClearHistory: _clearHistory,
                    onDeleteChat: _deleteChat,
                    onSelectAllMyMessages: _selectAllMyMessages,
                    onClearSelection: _clearSelection,
                    onDeleteSelectedMessages: _deleteSelectedMessages,
                  ),
                  Expanded(
                    child: ChatMessagesList(
                      selectedChat: selectedChat,
                      messages: _messages,
                      pendingQueue: _pendingQueue,
                      isLoading: _isLoading,
                      selectedMessageIds: _selectedMessageIds,
                      scrollController: _scrollController,
                      currentUserId: currentUserId,
                      onDeleteMessage: _deleteMessage,
                      onToggleMessageSelection: _toggleMessageSelection,
                      onCancelPending: _cancelPendingFromQueue,
                    ),
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
                      : ChatListWidget(
                          chats: _chats,
                          selectedChat: _selectedChat,
                          isLoading: _isLoading,
                          onSelectChat: _selectChat,
                          onDeleteChat: _deleteChat,
                        ),
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
                    messages: _messages,
                    selectedMessageIds: _selectedMessageIds,
                    isSelectionMode: _isSelectionMode,
                    currentUserId: currentUserId,
                    showBackButton: false,
                    onBack: _backToList,
                    onClearHistory: _clearHistory,
                    onDeleteChat: _deleteChat,
                    onSelectAllMyMessages: _selectAllMyMessages,
                    onClearSelection: _clearSelection,
                    onDeleteSelectedMessages: _deleteSelectedMessages,
                  ),
                  Expanded(
                    child: ChatMessagesList(
                      selectedChat: selectedChat,
                      messages: _messages,
                      pendingQueue: _pendingQueue,
                      isLoading: _isLoading,
                      selectedMessageIds: _selectedMessageIds,
                      scrollController: _scrollController,
                      currentUserId: currentUserId,
                      onDeleteMessage: _deleteMessage,
                      onToggleMessageSelection: _toggleMessageSelection,
                      onCancelPending: _cancelPendingFromQueue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
