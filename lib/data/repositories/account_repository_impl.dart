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
  Future<void> updateProfilePersonal({
    required String name,
    required String surname,
    required int gender,
    required String birthday,
    required String about,
  }) async {
    try {
      await dataSource.updateProfilePersonal(
        name: name,
        surname: surname,
        gender: gender,
        birthday: birthday,
        about: about,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AccountRepository: личные данные', e);
      throw ApiFailure('Ошибка сохранения профиля');
    }
  }

  @override
  Future<void> changeUsername(String username) async {
    try {
      await dataSource.changeUsername(username);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AccountRepository: смена логина', e);
      throw ApiFailure('Ошибка смены логина');
    }
  }

  @override
  Future<String> requestEmailChange(String newEmail) async {
    try {
      return await dataSource.requestEmailChange(newEmail);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AccountRepository: запрос смены почты', e);
      throw ApiFailure('Ошибка запроса смены почты');
    }
  }

  @override
  Future<void> verifyEmailChange(String verificationToken, String code) async {
    try {
      await dataSource.verifyEmailChange(verificationToken, code);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AccountRepository: подтверждение смены почты', e);
      throw ApiFailure('Ошибка подтверждения почты');
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
  Future<int> getConfidentialitySettings() async {
    try {
      return await dataSource.getConfidentialitySettings();
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AccountRepository: конфиденциальность', e);
      throw ApiFailure('Ошибка загрузки настроек приватности');
    }
  }

  @override
  Future<void> updateConfidentialitySettings(int messagePrivacy) async {
    try {
      await dataSource.updateConfidentialitySettings(messagePrivacy);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AccountRepository: сохранение конфиденциальности', e);
      throw ApiFailure('Ошибка сохранения настроек приватности');
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
