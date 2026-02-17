import 'package:voosu/domain/entities/auth_result.dart';
import 'package:voosu/domain/entities/auth_tokens.dart';
import 'package:voosu/domain/entities/login_code_challenge.dart';

abstract interface class AuthRepository {
  Future<LoginCodeChallenge> requestLoginCode(String email);

  Future<AuthResult> verifyLogin(String verificationToken, String code);

  Future<AuthTokens> refreshToken(String refreshToken);

  Future<void> logout();
}
