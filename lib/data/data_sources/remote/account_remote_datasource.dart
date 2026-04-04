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
import 'package:voosu/generated/grpc_pb/upload.pbgrpc.dart' as uploadpb;

abstract class IAccountRemoteDataSource {
  Future<void> changeUsername(String username);

  Future<void> updateProfilePersonal({
    required String name,
    required String surname,
    required int gender,
    required String birthday,
    required String about,
  });

  Future<String> requestEmailChange(String newEmail);

  Future<void> verifyEmailChange(String verificationToken, String code);

  Future<List<Device>> getDevices();

  Future<void> revokeDevice(int deviceId);

  Stream<accountpb.UpdateResponse> getUpdates();

  Future<accountpb.GetMissedUpdatesResponse> getMissedUpdates(int pts);

  Future<UploadProfilePhotoResult> uploadProfilePhoto(String fileId);

  Future<List<int>> getFile(String fileId);

  Future<accountpb.GetNotificationsResponse> getNotifications({
    int limit = 50,
    int offset = 0,
  });

  Future<void> markNotificationRead(int notificationId);

  Future<void> markAllNotificationsRead();

  Future<int> getConfidentialitySettings();

  Future<void> updateConfidentialitySettings(int messagePrivacy);
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
  Future<void> updateProfilePersonal({
    required String name,
    required String surname,
    required int gender,
    required String birthday,
    required String about,
  }) async {
    Logs().d('AccountRemoteDataSource: личные данные профиля');
    try {
      await _client.updateProfilePersonal(
        accountpb.UpdateProfilePersonalRequest(
          name: name.trim(),
          surname: surname.trim(),
          gender: gender,
          birthday: birthday.trim(),
          about: about.trim(),
        ),
      );
      Logs().i('AccountRemoteDataSource: профиль обновлён');
    } on GrpcError catch (e) {
      Logs().e('AccountRemoteDataSource: личные данные', e);
      throwGrpcError(e, 'Ошибка сохранения профиля');
    } catch (e) {
      Logs().e('AccountRemoteDataSource: личные данные', e);
      throw ApiFailure('Ошибка сохранения профиля');
    }
  }

  @override
  Future<void> changeUsername(String username) async {
    Logs().d('AccountRemoteDataSource: смена логина');
    try {
      await _client.changeUsername(
        accountpb.ChangeUsernameRequest(username: username.trim()),
      );
      Logs().i('AccountRemoteDataSource: логин изменён');
    } on GrpcError catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка смены логина', e);
      if (e.code == StatusCode.alreadyExists) {
        throw NetworkFailure(e.message ?? 'Этот логин уже занят');
      }
      throwGrpcError(e, 'Ошибка смены логина');
    } catch (e) {
      Logs().e('AccountRemoteDataSource: ошибка смены логина', e);
      throw ApiFailure('Ошибка смены логина');
    }
  }

  @override
  Future<String> requestEmailChange(String newEmail) async {
    Logs().d('AccountRemoteDataSource: запрос смены почты');
    try {
      final response = await _client.requestEmailChange(
        accountpb.RequestEmailChangeRequest(newEmail: newEmail.trim()),
      );
      Logs().i('AccountRemoteDataSource: код отправлен на новую почту');
      return response.verificationToken;
    } on GrpcError catch (e) {
      Logs().e('AccountRemoteDataSource: запрос смены почты', e);
      throwGrpcError(e, 'Не удалось отправить код');
    } catch (e) {
      Logs().e('AccountRemoteDataSource: запрос смены почты', e);
      throw ApiFailure('Ошибка запроса смены почты');
    }
  }

  @override
  Future<void> verifyEmailChange(String verificationToken, String code) async {
    Logs().d('AccountRemoteDataSource: подтверждение смены почты');
    try {
      await _client.verifyEmailChange(
        accountpb.VerifyEmailChangeRequest(
          verificationToken: verificationToken.trim(),
          code: code.trim(),
        ),
      );
      Logs().i('AccountRemoteDataSource: почта изменена');
    } on GrpcError catch (e) {
      Logs().e('AccountRemoteDataSource: подтверждение смены почты', e);
      throwGrpcError(e, 'Неверный код или срок действия истёк');
    } catch (e) {
      Logs().e('AccountRemoteDataSource: подтверждение смены почты', e);
      throw ApiFailure('Ошибка подтверждения почты');
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
  Future<UploadProfilePhotoResult> uploadProfilePhoto(String fileId) async {
    Logs().d('AccountRemoteDataSource: загрузка фото профиля');
    try {
      final request = accountpb.UploadProfilePhotoRequest(fileId: fileId);
      final response = await _client.uploadProfilePhoto(request);
      Logs().i('AccountRemoteDataSource: фото профиля загружено');
      return UploadProfilePhotoResult(
        photoId: response.photoId,
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
  Future<List<int>> getFile(String fileId) async {
    try {
      final request = uploadpb.GetFileRequest(
        fileId: fileId,
        offset: Int64(0),
      );
      final stream = _channelManager.fileClient.getFile(request);
      final out = <int>[];
      await for (final chunk in stream) {
        if (chunk.data.isNotEmpty) {
          out.addAll(chunk.data);
        }
      }
      return out;
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
  Future<int> getConfidentialitySettings() async {
    try {
      final r = await _client.getConfidentialitySettings(
        accountpb.GetConfidentialitySettingsRequest(),
      );
      return r.messagePrivacy;
    } on GrpcError catch (e) {
      Logs().e('AccountRemoteDataSource: конфиденциальность', e);
      throwGrpcError(e, 'Не удалось загрузить настройки приватности');
    } catch (e) {
      Logs().e('AccountRemoteDataSource: конфиденциальность', e);
      throw ApiFailure('Не удалось загрузить настройки приватности');
    }
  }

  @override
  Future<void> updateConfidentialitySettings(int messagePrivacy) async {
    try {
      await _client.updateConfidentialitySettings(
        accountpb.UpdateConfidentialitySettingsRequest(
          messagePrivacy: messagePrivacy,
        ),
      );
    } on GrpcError catch (e) {
      Logs().e('AccountRemoteDataSource: сохранение конфиденциальности', e);
      if (e.code == StatusCode.invalidArgument) {
        throw NetworkFailure(e.message ?? 'Некорректное значение');
      }
      throwGrpcError(e, 'Не удалось сохранить настройки приватности');
    } catch (e) {
      Logs().e('AccountRemoteDataSource: сохранение конфиденциальности', e);
      throw ApiFailure('Не удалось сохранить настройки приватности');
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
