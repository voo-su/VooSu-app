import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/grpc_channel_manager.dart';
import 'package:voosu/core/grpc_error_handler.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/core/reconnect_policy.dart';
import 'package:voosu/data/data_sources/local/user_local_data_source.dart';
import 'package:voosu/generated/grpc_pb/account.pbgrpc.dart' as accountpb;
import 'package:voosu/generated/grpc_pb/file.pbgrpc.dart' as filepb;

abstract class IAccountRemoteDataSource {
  Stream<accountpb.UpdateResponse> getUpdates();

  Future<accountpb.GetMissedUpdatesResponse> getMissedUpdates(int pts);

  Future<List<int>> getFile(int fileId);

  Future<accountpb.GetNotificationsResponse> getNotifications({
    int limit = 50,
    int offset = 0,
  });

  Future<void> markNotificationRead(int notificationId);

  Future<void> markAllNotificationsRead();
}

class AccountRemoteDataSource implements IAccountRemoteDataSource {
  final GrpcChannelManager _channelManager;
  final UserLocalDataSourceImpl _userLocal;

  AccountRemoteDataSource(
    this._channelManager,
    this._userLocal,
  );

  accountpb.AccountServiceClient get _client => _channelManager.accountClient;

  @override
  Future<List<int>> getFile(int fileId) async {
    try {
      final request = filepb.GetFileRequest(fileId: Int64(fileId));
      final response = await _channelManager.fileClient.getFile(request);
      return response.content;
    } on GrpcError catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка getFile', e);
      throwGrpcError(e, 'Ошибка загрузки файла');
    } catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка getFile', e);
      throw ApiFailure('Ошибка загрузки файла');
    }
  }

  @override
  Future<accountpb.GetNotificationsResponse> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final request = accountpb.GetNotificationsRequest(
        limit: limit,
        offset: offset,
      );
      return await _client.getNotifications(request);
    } on GrpcError catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка getNotifications', e);
      throwGrpcError(e, 'Ошибка загрузки уведомлений');
    } catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка getNotifications', e);
      throw ApiFailure('Ошибка загрузки уведомлений');
    }
  }

  @override
  Future<void> markNotificationRead(int notificationId) async {
    try {
      final request = accountpb.MarkNotificationReadRequest(
        notificationId: Int64(notificationId),
      );
      await _client.markNotificationRead(request);
    } on GrpcError catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка markNotificationRead', e);
      throwGrpcError(e, 'Ошибка отметки уведомления');
    } catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка markNotificationRead', e);
      throw ApiFailure('Ошибка отметки уведомления');
    }
  }

  @override
  Future<void> markAllNotificationsRead() async {
    try {
      final request = accountpb.MarkAllNotificationsReadRequest();
      await _client.markAllNotificationsRead(request);
    } on GrpcError catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка markAllNotificationsRead', e);
      throwGrpcError(e, 'Ошибка отметки уведомлений');
    } catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка markAllNotificationsRead', e);
      throw ApiFailure('Ошибка отметки уведомлений');
    }
  }

  @override
  Stream<accountpb.UpdateResponse> getUpdates() async* {
    const policy = ReconnectPolicy.hybrid();
    int attempt = 0;

    while (true) {
      final reqCtrl = StreamController<accountpb.UpdateRequest>();
      Timer? pingTimer;
      Duration pingInterval = const Duration(seconds: 30);
      bool connectedOnceThisAttempt = false;

      void startPinging() {
        pingTimer?.cancel();
        pingTimer = Timer.periodic(pingInterval, (_) {
          if (!reqCtrl.isClosed) {
            reqCtrl.add(
              accountpb.UpdateRequest(
                systemPingEvent: accountpb.UpdateSystemPingEvent(),
              ),
            );
          }
        });
      }

      try {
        startPinging();

        final syncState = await _userLocal.getSyncState();
        final currentPts = syncState['pts'] ?? 0;
        final currentDate = syncState['date'] ?? 0;

        reqCtrl.add(accountpb.UpdateRequest(
          state: accountpb.UpdateState(
            pts: Int64(currentPts),
            date: Int64(currentDate),
          ),
        ));

        Timer(const Duration(milliseconds: 1500), () {
          if (!reqCtrl.isClosed) {
            reqCtrl.add(accountpb.UpdateRequest(
              state: accountpb.UpdateState(
                pts: Int64(currentPts),
                date: Int64(currentDate),
              ),
            ));
          }
        });

        Stream<accountpb.UpdateResponse> respStream = _client.getUpdates(reqCtrl.stream);

        await for (final ev in respStream) {
          attempt = 0;
          if (!connectedOnceThisAttempt) {
            connectedOnceThisAttempt = true;
          }


          final updateSystem = ev.updateSystem;
          if (updateSystem.hasSystemPingIntervalEvent()) {
            final s = int.tryParse(updateSystem.systemPingIntervalEvent.pingInterval) ?? 30;
            pingInterval = Duration(seconds: s);
            startPinging();
          }

          if (updateSystem.hasSystemPingEvent()) {
            if (!reqCtrl.isClosed) {
              reqCtrl.add(accountpb.UpdateRequest(
                systemPongEvent: accountpb.UpdateSystemPongEvent(),
              ));
            }
          }

          yield ev;
        }

        final wait = policy.next(attempt);
        attempt++;
        Logs().i('getUpdates - дисконнект - переподключение ${wait.inMilliseconds} - $attempt');
        await Future.delayed(wait);
        continue;
      } catch (e) {
        final wait = policy.next(attempt);
        attempt++;
        Logs().e('getUpdates error: $e | переподключение ${wait.inMilliseconds} - $attempt');
        await Future.delayed(wait);
        continue;
      } finally {
        pingTimer?.cancel();
        reqCtrl.close();
        Logs().i('Ресурсы потока очищены');
      }
    }
  }

  @override
  Future<accountpb.GetMissedUpdatesResponse> getMissedUpdates(int pts) async {
    final request = accountpb.GetMissedUpdatesRequest(pts: Int64(pts));
    return _client.getMissedUpdates(request);
  }
}
