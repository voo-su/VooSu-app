import 'package:voosu/domain/entities/auth_result.dart';
import 'package:voosu/domain/entities/auth_tokens.dart';
import 'package:voosu/domain/entities/login_code_challenge.dart';
import 'package:voosu/generated/grpc_pb/auth.pb.dart' as grpc;
import 'package:voosu/data/mappers/user_mapper.dart';

abstract class AuthMapper {
  AuthMapper._();

  static LoginCodeChallenge sendLoginCodeResponseFromProto(
    grpc.SendLoginCodeResponse proto,
  ) {
    return LoginCodeChallenge(
      verificationToken: proto.verificationToken,
      expiresInSec: proto.expiresIn.toInt(),
    );
  }

  static AuthResult loginResponseFromProto(grpc.LoginResponse proto) {
    return AuthResult(
      user: UserMapper.fromProto(proto.user),
      tokens: AuthTokens(
        accessToken: proto.accessToken,
        refreshToken: proto.refreshToken,
      ),
    );
  }

  static AuthTokens refreshTokenResponseFromProto(
    grpc.RefreshTokenResponse proto,
  ) {
    return AuthTokens(
      accessToken: proto.accessToken,
      refreshToken: proto.refreshToken,
    );
  }
}
