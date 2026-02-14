import 'package:grpc/grpc.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/log/logs.dart';

const String kSessionExpiredMessage = 'Сессия истекла, войдите снова';

Never throwGrpcError(
  GrpcError e,
  String networkMessage, {
  String? unauthenticatedMessage,
}) {
  if (e.code == StatusCode.unauthenticated) {
    Logs().w('gRPC: unauthenticated', e);
    throw UnauthorizedFailure(unauthenticatedMessage ?? kSessionExpiredMessage);
  }

  final invalidArgMessage = e.message;
  if (e.code == StatusCode.invalidArgument && invalidArgMessage != null && invalidArgMessage.isNotEmpty) {
    Logs().e('gRPC: $networkMessage', e);
    throw NetworkFailure(invalidArgMessage);
  }

  Logs().e('gRPC: $networkMessage', e);
  throw NetworkFailure(networkMessage);
}
