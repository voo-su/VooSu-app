import 'package:grpc/grpc.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/grpc_channel_manager.dart';
import 'package:voosu/core/grpc_error_handler.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/mappers/auth_mapper.dart';
import 'package:voosu/domain/entities/auth_result.dart';
import 'package:voosu/domain/entities/auth_tokens.dart';
import 'package:voosu/domain/entities/login_code_challenge.dart';
import 'package:voosu/generated/grpc_pb/auth.pbgrpc.dart' as authpb;

abstract class IAuthRemoteDataSource {
  Future<LoginCodeChallenge> requestLoginCode(String email);

  Future<AuthResult> verifyLogin(String verificationToken, String code);

  Future<AuthTokens> refreshToken(String refreshToken);

  Future<void> logout();
}

class AuthRemoteDataSource implements IAuthRemoteDataSource {
  final GrpcChannelManager _channelManager;

  AuthRemoteDataSource(this._channelManager);

  authpb.AuthServiceClient get _client => _channelManager.authClient;

  @override
  Future<LoginCodeChallenge> requestLoginCode(String email) async {
    Logs().d('AuthRemoteDataSource: запрос кода для $email');
    try {
      final request = authpb.LoginRequest(email: email);
      final response = await _client.login(request);
      final challenge = AuthMapper.sendLoginCodeResponseFromProto(response);
      Logs().i('AuthRemoteDataSource: код отправлен');
      return challenge;
    } on GrpcError catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка запроса кода (gRPC)', e);
      throwGrpcError(
        e,
        'Ошибка отправки кода',
        unauthenticatedMessage: 'Проверьте email',
      );
    } catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка запроса кода', e);
      throw ApiFailure('Ошибка отправки кода');
    }
  }

  @override
  Future<AuthResult> verifyLogin(
    String verificationToken,
    String code,
  ) async {
    Logs().d('AuthRemoteDataSource: проверка кода');
    try {
      final request = authpb.VerifyLoginRequest(
        verificationToken: verificationToken,
        code: code,
      );
      final response = await _client.verifyLogin(request);
      final result = AuthMapper.loginResponseFromProto(response);
      Logs().i('AuthRemoteDataSource: вход выполнен');
      return result;
    } on GrpcError catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка проверки кода (gRPC)', e);
      throwGrpcError(
        e,
        'Ошибка входа',
        unauthenticatedMessage: 'Неверный или просроченный код',
      );
    } catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка проверки кода', e);
      throw ApiFailure('Ошибка входа');
    }
  }

  @override
  Future<AuthTokens> refreshToken(String refreshToken) async {
    Logs().d('AuthRemoteDataSource: обновление токена');
    try {
      final request = authpb.RefreshTokenRequest(refreshToken: refreshToken);

      final response = await _client.refreshToken(request);
      final tokens = AuthMapper.refreshTokenResponseFromProto(response);
      Logs().i('AuthRemoteDataSource: токен обновлён');

      return tokens;
    } on GrpcError catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка обновления токена', e);
      throwGrpcError(
        e,
        'Ошибка обновления токена',
        unauthenticatedMessage: 'Недействительный refresh token',
      );
    } catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка обновления токена', e);
      throw ApiFailure('Ошибка обновления токена');
    }
  }

  @override
  Future<void> logout() async {
    Logs().d('AuthRemoteDataSource: выход');
    try {
      final request = authpb.LogoutRequest();

      await _client.logout(request);
      Logs().i('AuthRemoteDataSource: выход выполнен');
    } on GrpcError catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка выхода', e);
      throwGrpcError(e, 'Ошибка выхода');
    } catch (e) {
      Logs().e('AuthRemoteDataSource: ошибка выхода', e);
      throw ApiFailure('Ошибка выхода');
    }
  }
}
