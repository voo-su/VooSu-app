import 'package:voosu/domain/repositories/account_repository.dart';

class VerifyEmailChangeUseCase {
  VerifyEmailChangeUseCase(this._repository);

  final AccountRepository _repository;

  Future<void> call(String verificationToken, String code) => _repository.verifyEmailChange(verificationToken.trim(), code.trim());
}
