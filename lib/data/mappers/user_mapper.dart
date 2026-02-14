import 'package:voosu/domain/entities/user.dart';
import 'package:voosu/generated/grpc_pb/common.pb.dart' as grpc;

abstract class UserMapper {
  UserMapper._();

  static User fromProto(grpc.User proto) {
    return User(
      id: proto.id.toInt(),
      username: proto.username,
      name: proto.name,
      surname: proto.surname,
      avatarFileId: proto.avatarFileId > 0 ? proto.avatarFileId.toInt() : null,
    );
  }

  static List<User> listFromProto(List<grpc.User> protos) {
    return protos.map(fromProto).toList();
  }
}
