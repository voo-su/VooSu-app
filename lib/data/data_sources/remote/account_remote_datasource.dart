import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:voosu/core/connection_status.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/grpc_channel_manager.dart';
import 'package:voosu/core/grpc_error_handler.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/core/reconnect_policy.dart';
import 'package:voosu/data/data_sources/local/user_local_data_source.dart';
import 'package:voosu/domain/entities/device.dart';
import 'package:voosu/domain/repositories/account_repository.dart';
import 'package:voosu/generated/grpc_pb/account.pbgrpc.dart' as accountpb;
import 'package:voosu/generated/grpc_pb/file.pbgrpc.dart' as filepb;

abstract class IAccountRemoteDataSource {
  Future<void> changePassword(
    String oldPassword,
    String newPassword, [
    String? currentRefreshToken,
  ]);

  Future<List<Device>> getDevices();

  Future<void> revokeDevice(int deviceId);

  Stream<accountpb.UpdateResponse> getUpdates();

  Future<accountpb.GetMissedUpdatesResponse> getMissedUpdates(int pts);

  Future<UploadProfilePhotoResult> uploadProfilePhoto(int fileId);

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
  final ConnectionStatusService? connectionStatusService;

  AccountRemoteDataSource(
    this._channelManager,
    this._userLocal,
    this.connectionStatusService,
  );

  accountpb.AccountServiceClient get _client => _channelManager.accountClient;

  @override
  Future<void> changePassword(
    String oldPassword,
    String newPassword,
    [String? currentRefreshToken]
  ) async {
    Logs().d('AccountRemoteDataSource: смена пароля');
    try {
      final request = accountpb.ChangePasswordRequest(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      final refreshToken = currentRefreshToken ?? _userLocal.refreshToken;
      if (refreshToken != null && refreshToken.trim().isNotEmpty) {
        request.currentRefreshToken = refreshToken.trim();
      }

      await _client.changePassword(request);
      Logs().i('AccountRemoteDataSource: пароль изменён');
    } on GrpcError catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка смены пароля', e);
      if (e.code == StatusCode.invalidArgument) {
        throw NetworkFailure('Неверные данные');
      }

      throwGrpcError(e, 'Ошибка смены пароля');
    } catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка смены пароля', e);
      throw ApiFailure('Ошибка смены пароля');
    }
  }

  @override
  Future<List<Device>> getDevices() async {
    Logs().d('AccountRemoteDataSource: список устройств');
    try {
      final request = accountpb.GetDevicesRequest();
      final response = await _client.getDevices(request);
      final devices = response.devices.map((d) => Device(
        id: d.id,
        createdAt: d.createdAtSeconds.toInt(),
      ))
      .toList();

      Logs().i('AccountRemoteDataSource: получено ${devices.length} устройств');

      return devices;
    } on GrpcError catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка списка устройств', e);
      throwGrpcError(e, 'Ошибка загрузки устройств');
    } catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка списка устройств', e);
      throw ApiFailure('Ошибка загрузки устройств');
    }
  }

  @override
  Future<void> revokeDevice(int deviceId) async {
    Logs().d('AccountRemoteDataSource: отзыв устройства $deviceId');
    try {
      final request = accountpb.RevokeDeviceRequest(deviceId: deviceId);
      await _client.revokeDevice(request);
      Logs().i('AccountRemoteDataSource: устройство отозвано');
    } on GrpcError catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка отзыва устройства', e);
      if (e.code == StatusCode.notFound) {
        throw NetworkFailure('Устройство не найдено');
      }
      throwGrpcError(e, 'Ошибка отзыва устройства');
    } catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка отзыва устройства', e);
      throw ApiFailure('Ошибка отзыва устройства');
    }
  }

  @override
  Future<UploadProfilePhotoResult> uploadProfilePhoto(int fileId) async {
    Logs().d('AccountRemoteDataSource: загрузка фото профиля');
    try {
      final request = accountpb.UploadProfilePhotoRequest(fileId: Int64(fileId));
      final response = await _client.uploadProfilePhoto(request);
      Logs().i('AccountRemoteDataSource: фото профиля загружено');
      return UploadProfilePhotoResult(
        avatarFileId: response.avatarFileId.toInt(),
      );
    } on GrpcError catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка загрузки фото', e);
      throwGrpcError(e, 'Ошибка загрузки фото');
    } catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка загрузки фото', e);
      throw ApiFailure('Ошибка загрузки фото');
    }
  }

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
        connectionStatusService?.setConnecting();
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
            connectionStatusService?.setConnected();
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
        connectionStatusService?.setDisconnected();
        Logs().i('getUpdates - дисконнект - переподключение ${wait.inMilliseconds} - $attempt');
        await Future.delayed(wait);
        continue;
      } catch (e) {
        final wait = policy.next(attempt);
        attempt++;
        connectionStatusService?.setDisconnected();
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
