import 'dart:async';
import 'dart:convert';

import 'package:voosu/core/log/logs.dart';
import 'package:voosu/core/reconnect_policy.dart';
import 'package:voosu/data/data_sources/local/user_local_data_source.dart';
import 'package:voosu/data/data_sources/remote/account_remote_datasource.dart';
import 'package:voosu/data/db/app_database.dart';
import 'package:voosu/data/mappers/message_mapper.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/entities/message_deleted_payload.dart';
import 'package:voosu/domain/entities/message_read_payload.dart';
import 'package:voosu/domain/entities/attachment_upload.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';
import 'package:voosu/domain/usecases/chat/get_chat_messages_usecase.dart';
import 'package:voosu/domain/usecases/chat/get_chats_usecase.dart';
import 'package:voosu/generated/grpc_pb/account.pb.dart';
import 'package:voosu/generated/grpc_pb/account.pbgrpc.dart' as account_pb;

class PtsSyncService {
  final IAccountRemoteDataSource _accountRemoteDataSource;
  final UserLocalDataSource _userLocalDataSource;
  final GetChatsUseCase _getChatsUseCase;
  final GetChatMessagesUseCase? _getChatMessagesUseCase;
  final ChatRepository? _chatRepository;
  final ReconnectPolicy _reconnectPolicy;
  final AppDatabase? _cacheDb;

  StreamSubscription<UpdateResponse>? _updatesSubscription;
  Timer? _backgroundRefreshTimer;
  bool _isSyncing = false;
  static const Duration _backgroundSyncInterval = Duration(minutes: 5);
  Completer<void>? _initialSyncCompleter;
  Completer<void>? _cycleCompleter;
  bool _running = false;
  int _reconnectAttempt = 0;
  static const int maxPtsDifference = 1000;
  static const int _updatesBatchSize = 50;
  static const int _tooManyUpdatesThreshold = 500;
  static const Duration _batchYieldDuration = Duration(milliseconds: 16);

  bool _initialStateRetrieved = false;

  final StreamSink<Message>? _newMessageSink;
  final StreamSink<MessageDeletedPayload>? _messageDeletedSink;
  final StreamSink<MessageReadPayload>? _messageReadSink;
  final StreamSink<int>? _userTypingSink;
  final StreamSink<Object?>? _chatListRefreshSink;
  final StreamSink<Object?>? _syncRestoredSink;

  static const int _initialMessagesPerChat = 50;
  static const Duration _pullInterval = Duration(seconds: 30);

  bool _wasDisconnected = false;
  Timer? _pullTimer;
  UpdateResponse? _pendingPullResponse;

  PtsSyncService(
    this._accountRemoteDataSource,
    this._userLocalDataSource,
    this._getChatsUseCase, {
    GetChatMessagesUseCase? getChatMessagesUseCase,
    ChatRepository? chatRepository,
    ReconnectPolicy? reconnectPolicy,
    AppDatabase? cacheDb,
    StreamSink<Message>? newMessageSink,
    StreamSink<MessageDeletedPayload>? messageDeletedSink,
    StreamSink<MessageReadPayload>? messageReadSink,
    StreamSink<int>? userTypingSink,
    StreamSink<Object?>? chatListRefreshSink,
    StreamSink<Object?>? syncRestoredSink,
  })  : _getChatMessagesUseCase = getChatMessagesUseCase,
        _chatRepository = chatRepository,
        _reconnectPolicy = reconnectPolicy ?? const ReconnectPolicy.hybrid(),
        _cacheDb = cacheDb,
        _newMessageSink = newMessageSink,
        _messageDeletedSink = messageDeletedSink,
        _messageReadSink = messageReadSink,
        _userTypingSink = userTypingSink,
        _chatListRefreshSink = chatListRefreshSink,
        _syncRestoredSink = syncRestoredSink;

  Future<void> startSync() async {
    if (_running) {
      Logs().d('PtsSyncService: синхронизация уже запущена');
      return;
    }

    _running = true;
    _reconnectAttempt = 0;
    _startPullTimer();

    while (_running) {
      try {
        await _runOneSyncCycle();
      } catch (e, stackTrace) {
        Logs().e('Ошибка цикла синхронизации', e, stackTrace);
      }

      if (!_running) break;

      final wait = _reconnectPolicy.next(_reconnectAttempt);
      _reconnectAttempt++;
      Logs().i('PtsSyncService: переподключение через ${wait.inMilliseconds} мс (попытка $_reconnectAttempt)');
      await Future.delayed(wait);
    }
  }

  Future<void> _runOneSyncCycle() async {
    _initialSyncCompleter = Completer<void>();
    _cycleCompleter = Completer<void>();

    final updatesStream = _accountRemoteDataSource.getUpdates();

    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = Timer.periodic(_backgroundSyncInterval, (_) async {
      if (!_running) {
        return;
      }

      try {
        await _getChatsUseCase();
        _chatListRefreshSink?.add(null);
      } catch (_) {}
    });

    _updatesSubscription = updatesStream.listen(
      (updateResponse) => _handleUpdateResponse(updateResponse),
      onError: (error, stackTrace) {
        Logs().e('Ошибка в потоке обновлений', error, stackTrace);
        _wasDisconnected = true;
        _backgroundRefreshTimer?.cancel();
        _backgroundRefreshTimer = null;
        if (!(_cycleCompleter?.isCompleted ?? true)) {
          _cycleCompleter?.complete();
        }
      },
      onDone: () {
        Logs().i('Поток обновлений завершен');
        _wasDisconnected = true;
        _backgroundRefreshTimer?.cancel();
        _backgroundRefreshTimer = null;
        if (!(_cycleCompleter?.isCompleted ?? true)) {
          _cycleCompleter?.complete();
        }
      },
      cancelOnError: false,
    );

    await _cycleCompleter!.future;
  }

  Future<void> _performFullResync() async {
    try {
      final chats = await _getChatsUseCase();
      Logs().i('Загружено ${chats.length} чатов при полной пересинхронизации');
      _chatListRefreshSink?.add(null);
      if (_getChatMessagesUseCase != null) {
        for (final chat in chats) {
          try {
            final peerUserId = chat.isGroup ? null : chat.peerUserId;
            final peerGroupId = chat.isGroup ? chat.peerGroupId : null;
            await _getChatMessagesUseCase(
              peerUserId: peerUserId,
              peerGroupId: peerGroupId,
              messageId: 0,
              limit: _initialMessagesPerChat,
            );
          } catch (e) {
            Logs().d('PtsSyncService: не удалось подгрузить историю чата ${chat.id}: $e');
          }
        }
      }
    } catch (e, stackTrace) {
      Logs().e('Ошибка при полной пересинхронизации', e, stackTrace);
      rethrow;
    }
  }

  Future<void> stopSync() async {
    _running = false;
    _pullTimer?.cancel();
    _pullTimer = null;
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = null;
    await _updatesSubscription?.cancel();
    _updatesSubscription = null;

    if (_initialSyncCompleter != null && !_initialSyncCompleter!.isCompleted) {
      _initialSyncCompleter!.completeError(Exception('Синхронизация остановлена'));
    }
    if (_cycleCompleter != null && !_cycleCompleter!.isCompleted) {
      _cycleCompleter!.complete();
    }

    Logs().i('PtsSyncService: синхронизация остановлена');
  }

  Future<void> forceFullSync() async {
    await _userLocalDataSource.clearSyncState();
    _initialStateRetrieved = false;
    await startSync();
  }

  void _startPullTimer() {
    _pullTimer?.cancel();
    _pullTimer = Timer.periodic(_pullInterval, (_) {
      if (!_running) {
        return;
      }
      _runPull();
    });
  }

  Future<void> _runPull() async {
    try {
      final syncState = await _userLocalDataSource.getSyncState();
      final pts = syncState['pts'] is int ? syncState['pts'] as int : 0;
      final resp = await _accountRemoteDataSource.getMissedUpdates(pts);
      final updates = resp.updates;
      if (updates.isEmpty && !resp.hasState()) {
        return;
      }
      final synthetic = UpdateResponse(
        updates: updates,
        state: resp.hasState() ? resp.state : null,
      );
      if (_isSyncing) {
        _pendingPullResponse = synthetic;
      } else {
        await _handleUpdateResponse(synthetic);
      }
    } catch (e, stackTrace) {
      Logs().d('PtsSyncService: pull getMissedUpdates: $e', stackTrace);
    }
  }

  Future<void> _handleUpdateResponse(account_pb.UpdateResponse response) async {
    try {
      if (_isSyncing) return;
      _isSyncing = true;

      int? serverPts;
      int? serverDate;
      if (response.hasState()) {
        final state = response.state;
        serverPts = state.pts.toInt();
        serverDate = state.date.toInt();

        if (!_initialStateRetrieved) {
          final localSyncState = await _userLocalDataSource.getSyncState();
          final localPts = localSyncState['pts'] ?? 0;
          Logs().i('Состояние: localPts=$localPts, serverPts=$serverPts, difference=${serverPts - localPts}');
          if (localPts == 0 || serverPts - localPts > maxPtsDifference) {
            Logs().i('Расхождение pts слишком большое (${serverPts - localPts}), полная пересинхронизация');
            await _performFullResync();
          }
          _initialStateRetrieved = true;
        }
      }

      final updates = response.updates;
      final updatesCount = updates.length;

      if (updatesCount > _tooManyUpdatesThreshold) {
        Logs().i('Слишком много обновлений ($updatesCount > $_tooManyUpdatesThreshold): сброс кэша и полная пересинхронизация');
        await _cacheDb?.clearCache();
        await _userLocalDataSource.clearSyncState();
        await _performFullResync();
        if (serverPts != null && serverDate != null) {
          await _userLocalDataSource.setSyncState(serverPts, serverDate);
        }
      } else if (updatesCount > _updatesBatchSize) {
        for (var i = 0; i < updatesCount; i += _updatesBatchSize) {
          final end = (i + _updatesBatchSize).clamp(0, updatesCount);
          for (var j = i; j < end; j++) {
            await _processUpdate(updates[j]);
          }

          if (end < updatesCount) {
            await Future.delayed(_batchYieldDuration);
          }
        }
      } else {
        for (final update in updates) {
          await _processUpdate(update);
        }
      }

      if (serverPts != null && serverDate != null) {
        await _userLocalDataSource.setSyncState(serverPts, serverDate);
      }

      if (_initialSyncCompleter != null && !_initialSyncCompleter!.isCompleted) {
        _initialSyncCompleter!.complete();
        _initialSyncCompleter = null;
      }

      if (response.hasState()) {
        if (_wasDisconnected) {
          _wasDisconnected = false;
          _syncRestoredSink?.add(null);
          Logs().d('PtsSyncService: соединение восстановлено, уведомление подписчиков');
        }
        _retryPendingMessages();
      }

      _isSyncing = false;

      while (_pendingPullResponse != null) {
        final pending = _pendingPullResponse!;
        _pendingPullResponse = null;
        await _handleUpdateResponse(pending);
      }
    } catch (e, stackTrace) {
      Logs().e('Ошибка обработки обновления', e, stackTrace);
      _isSyncing = false;

      if (_initialSyncCompleter != null && !_initialSyncCompleter!.isCompleted) {
        _initialSyncCompleter!.completeError(e, stackTrace);
      }
    }
  }

  void reset() {
    _initialStateRetrieved = false;
  }

  Future<void> _retryPendingMessages() async {
    final repo = _chatRepository;
    if (repo == null) {
      return;
    }

    try {
      final list = await repo.getPendingOutgoingMessages();
      for (final p in list) {
        try {
          final peerUserId = p['peerUserId'] as int? ?? 0;
          final peerGroupId = p['peerGroupId'] as int? ?? 0;
          List<AttachmentUpload>? attachments;
          final json = p['attachmentsJson'] as String?;
          if (json != null && json.isNotEmpty) {
            final list = jsonDecode(json) as List<dynamic>?;
            if (list != null && list.isNotEmpty) {
              attachments = list.map((e) {
                final m = e as Map<String, dynamic>;
                return AttachmentUpload(
                  filename: m['filename'] as String? ?? '',
                  fileId: (m['fileId'] as num?)?.toInt() ?? 0,
                );
              }).toList();
            }
          }

          await repo.sendMessage(
            peerUserId: peerUserId == 0 ? null : peerUserId,
            peerGroupId: peerGroupId == 0 ? null : peerGroupId,
            content: p['content'] as String? ?? '',
            replyToMessageId: p['replyToId'] as int? ?? 0,
            attachments: attachments,
          );
          await repo.removePendingMessage(p['localId'] as String);
          Logs().d('PtsSyncService: отправлено сообщение из очереди ${p['localId']}');
        } catch (e) {
          Logs().d('PtsSyncService: не удалось отправить из очереди: $e');
        }
      }
    } catch (e) {
      Logs().d('PtsSyncService: retryPendingMessages: $e');
    }
  }

  Future<void> _processUpdate(account_pb.Update update) async {
    try {
      if (update.hasNewMessage()) {
        await _processNewMessage(update.newMessage);
      }

      if (update.hasMessageDeleted()) {
        await _processMessageDeleted(update.messageDeleted);
      }

      if (update.hasMessageRead()) {
        await _processMessageRead(update.messageRead);
      }

      if (update.hasUserTyping()) {
        await _processUserTyping(update.userTyping);
      }
    } catch (e, stackTrace) {
      Logs().e('Ошибка обработки обновления', e, stackTrace);
    }
  }

  Future<void> _processNewMessage(account_pb.UpdateNewMessage update) async {
    try {
      if (!update.hasMessage()) {
        return;
      }

      final message = MessageMapper.fromProto(update.message);
      _newMessageSink?.add(message);
      _chatListRefreshSink?.add(null);
      Logs().d('PtsSyncService: новое сообщение peer=${message.peerUserId} from=${message.fromPeerUserId} id=${message.id}');
      unawaited(_cacheDb?.cacheMessage(message) ?? Future.value());
    } catch (e, stackTrace) {
      Logs().e('Ошибка обработки нового сообщения', e, stackTrace);
    }
  }

  Future<void> _processMessageDeleted(account_pb.UpdateMessageDeleted update) async {
    try {
      if (update.messageIds.isEmpty) {
        return;
      }

      final messageIds = update.messageIds.map((id) => id.toInt()).toList();
      await _cacheDb?.deleteCachedMessages(messageIds);

      final payload = MessageDeletedPayload(
        peerId: update.peer.userId.toInt(),
        fromPeerId: update.fromPeer.userId.toInt(),
        messageIds: messageIds,
      );
      _messageDeletedSink?.add(payload);
      _chatListRefreshSink?.add(null);
      Logs().d('PtsSyncService: удаление сообщений peer=${payload.peerId} from=${payload.fromPeerId} ids=${payload.messageIds}');
    } catch (e, stackTrace) {
      Logs().e('Ошибка обработки удаления сообщений', e, stackTrace);
    }
  }

  Future<void> _processMessageRead(UpdateMessageRead update) async {
    try {
      final payload = MessageReadPayload(
        readerUserId: update.readerUserId.toInt(),
        peerUserId: update.peerUserId.toInt(),
        lastReadMessageId: update.lastReadMessageId.toInt(),
      );
      _messageReadSink?.add(payload);
      _chatListRefreshSink?.add(null);
      Logs().d('PtsSyncService: сообщения прочитаны reader=${payload.readerUserId} peer=${payload.peerUserId} upTo=${payload.lastReadMessageId}');
    } catch (e, stackTrace) {
      Logs().e('Ошибка обработки прочтения сообщений', e, stackTrace);
    }
  }

  Future<void> _processUserTyping(UpdateUserTyping update) async {
    try {
      final userId = update.userId.toInt();
      _userTypingSink?.add(userId);
      Logs().d('PtsSyncService: печатает userId=$userId');
    } catch (e, stackTrace) {
      Logs().e('Ошибка обработки печатает', e, stackTrace);
    }
  }

}
