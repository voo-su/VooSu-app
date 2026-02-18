import 'package:voosu/domain/entities/auth_result.dart';
import 'package:voosu/domain/entities/login_code_challenge.dart';
import 'package:voosu/domain/repositories/auth_repository.dart';

class RequestLoginCodeUseCase {
  final AuthRepository _repository;

  RequestLoginCodeUseCase(this._repository);

  Future<LoginCodeChallenge> call(String email) =>
      _repository.requestLoginCode(email);
}

class VerifyLoginUseCase {
  final AuthRepository _repository;

  VerifyLoginUseCase(this._repository);

  Future<AuthResult> call(String verificationToken, String code) =>
      _repository.verifyLogin(verificationToken, code);
}
