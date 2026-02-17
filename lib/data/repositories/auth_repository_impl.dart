import 'package:voosu/core/failures.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/data_sources/remote/auth_remote_datasource.dart';
import 'package:voosu/domain/entities/auth_result.dart';
import 'package:voosu/domain/entities/auth_tokens.dart';
import 'package:voosu/domain/entities/login_code_challenge.dart';
import 'package:voosu/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final IAuthRemoteDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<LoginCodeChallenge> requestLoginCode(String email) async {
    try {
      return await dataSource.requestLoginCode(email);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AuthRepository: ошибка отправки кода', e);
      throw ApiFailure('Не удалось отправить код');
    }
  }

  @override
  Future<AuthResult> verifyLogin(String verificationToken, String code) async {
    try {
      return await dataSource.verifyLogin(verificationToken, code);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AuthRepository: ошибка проверки кода', e);
      throw ApiFailure('Ошибка входа');
    }
  }

  @override
  Future<AuthTokens> refreshToken(String refreshToken) async {
    try {
      return await dataSource.refreshToken(refreshToken);
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AuthRepository: неожиданная ошибка обновления токена', e);
      throw ApiFailure('Ошибка обновления токена');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dataSource.logout();
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AuthRepository: неожиданная ошибка выхода', e);
      throw ApiFailure('Ошибка выхода');
    }
  }
}
