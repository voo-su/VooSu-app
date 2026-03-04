import 'package:voosu/domain/entities/account_update.dart';
import 'package:voosu/domain/entities/device.dart';

abstract interface class AccountRepository {
  Future<Stream<AccountUpdate>> getUpdates();

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

  Future<UploadProfilePhotoResult> uploadProfilePhoto(int fileId);

  Future<List<int>> getFile(int fileId);

  void cacheFileBytes(int fileId, List<int> bytes);
}

class UploadProfilePhotoResult {
  final int avatarFileId;

  UploadProfilePhotoResult({required this.avatarFileId});
}
