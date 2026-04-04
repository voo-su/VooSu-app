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

  Future<int> getConfidentialitySettings();

  Future<void> updateConfidentialitySettings(int messagePrivacy);

  Future<UploadProfilePhotoResult> uploadProfilePhoto(String fileId);

  Future<List<int>> getFile(String fileId);
}

class UploadProfilePhotoResult {
  final String photoId;

  UploadProfilePhotoResult({required this.photoId});
}
