import 'package:voosu/domain/entities/account_update.dart';
import 'package:voosu/domain/entities/device.dart';

abstract interface class AccountRepository {
  Future<Stream<AccountUpdate>> getUpdates();

  Future<void> changePassword(
    String oldPassword,
    String newPassword, [
    String? currentRefreshToken,
  ]);

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
