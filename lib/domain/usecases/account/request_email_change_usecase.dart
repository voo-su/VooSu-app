import 'package:voosu/domain/repositories/account_repository.dart';

class RequestEmailChangeUseCase {
  RequestEmailChangeUseCase(this._repository);

  final AccountRepository _repository;

  Future<String> call(String newEmail) => _repository.requestEmailChange(newEmail.trim());
}
