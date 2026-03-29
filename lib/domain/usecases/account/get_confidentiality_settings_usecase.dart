import 'package:voosu/domain/repositories/account_repository.dart';

class GetConfidentialitySettingsUseCase {
  GetConfidentialitySettingsUseCase(this._repository);

  final AccountRepository _repository;

  Future<int> call() => _repository.getConfidentialitySettings();
}
