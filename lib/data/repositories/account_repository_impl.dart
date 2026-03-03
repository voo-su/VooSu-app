import 'package:voosu/core/failures.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/data_sources/remote/account_remote_datasource.dart';
import 'package:voosu/data/mappers/account_update_mapper.dart';
import 'package:voosu/domain/entities/account_update.dart';
import 'package:voosu/domain/entities/device.dart';
import 'package:voosu/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final IAccountRemoteDataSource dataSource;

  AccountRepositoryImpl(this.dataSource);

  @override
  Future<Stream<AccountUpdate>> getUpdates() async {
    Logs().i('AccountRepositoryImpl - getUpdates');

    return dataSource.getUpdates().asyncExpand((response) async* {
      Logs().i('ChatRepositoryImpl - getUpdates ${response.updates}');

      for (final update in response.updates) {
        final domainUpdate = AccountUpdateMapper.fromGrpc(update);
        if (domainUpdate != null) {
          yield domainUpdate;
        }
      }
    });
  }

  @override
  Future<void> changePassword(
    String oldPassword,
    String newPassword,
    [String? currentRefreshToken]
  ) async {
    try {
      await dataSource.changePassword(
        oldPassword,
        newPassword,
        currentRefreshToken,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AccountRepository: неожиданная ошибка смены пароля', e);
      throw ApiFailure('Ошибка смены пароля');
    }
  }

  @override
  Future<List<Device>> getDevices() async {
    try {
      return await dataSource.getDevices();
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AccountRepository: неожиданная ошибка списка устройств', e);
      throw ApiFailure('Ошибка загрузки устройств');
    }
  }

  @override
  Future<void> revokeDevice(int deviceId) async {
    try {
      await dataSource.revokeDevice(deviceId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AccountRepository: неожиданная ошибка отзыва устройства', e);
      throw ApiFailure('Ошибка отзыва устройства');
    }
  }

  @override
  Future<UploadProfilePhotoResult> uploadProfilePhoto(int fileId) async {
    try {
      return await dataSource.uploadProfilePhoto(fileId);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AccountRepository: ошибка загрузки фото', e);
      throw ApiFailure('Ошибка загрузки фото');
    }
  }

  final Map<int, List<int>> _fileCache = {};

  @override
  Future<List<int>> getFile(int fileId) async {
    final cached = _fileCache[fileId];
    if (cached != null) return cached;
    try {
      final bytes = await dataSource.getFile(fileId);
      _fileCache[fileId] = bytes;
      return bytes;
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AccountRepository: ошибка getFile', e);
      throw ApiFailure('Ошибка загрузки файла');
    }
  }

  @override
  void cacheFileBytes(int fileId, List<int> bytes) {
    _fileCache[fileId] = bytes;
  }
}
