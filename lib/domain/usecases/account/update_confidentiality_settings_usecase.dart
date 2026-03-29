import 'package:voosu/domain/repositories/account_repository.dart';

class UpdateConfidentialitySettingsUseCase {
  UpdateConfidentialitySettingsUseCase(this._repository);

  final AccountRepository _repository;

  Future<void> call(int messagePrivacy) => _repository.updateConfidentialitySettings(messagePrivacy);
}
