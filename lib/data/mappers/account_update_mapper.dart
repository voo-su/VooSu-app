import 'package:voosu/data/mappers/message_mapper.dart';
import 'package:voosu/domain/entities/account_update.dart';
import 'package:voosu/generated/grpc_pb/account.pb.dart' as grpc;

abstract class AccountUpdateMapper {
  AccountUpdateMapper._();

  static AccountUpdate? fromGrpc(grpc.Update proto) {
    if (proto.hasUserStatus()) {
      final us = proto.userStatus;
      return UserStatusAccountUpdate(
        userId: us.userId.toInt(),
        status: us.status,
      );
    }

    if (proto.hasNewMessage() && proto.newMessage.hasMessage()) {
      final msg = proto.newMessage.message;
      return NewMessageAccountUpdate(message: MessageMapper.fromProto(msg));
    }

    return null;
  }
}
