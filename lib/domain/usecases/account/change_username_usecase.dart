import 'package:voosu/domain/repositories/account_repository.dart';

class ChangeUsernameUseCase {
  ChangeUsernameUseCase(this._repository);

  final AccountRepository _repository;

  Future<void> call(String username) => _repository.changeUsername(username.trim());
}
