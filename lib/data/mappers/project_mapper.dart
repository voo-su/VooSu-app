import 'package:voosu/domain/entities/project.dart';
import 'package:voosu/generated/grpc_pb/project.pb.dart' as projectpb;

class ProjectMapper {
  static Project fromProto(projectpb.Project proto) {
    return Project(id: proto.id.toInt(), name: proto.name);
  }

  static Project fromGetProjectResponse(projectpb.GetProjectResponse resp) {
    return Project(
      id: resp.id.toInt(),
      name: resp.name,
      currentUserRole: resp.hasCurrentUserRole() ? resp.currentUserRole : null,
    );
  }

  static List<Project> listFromProto(Iterable<projectpb.Project> list) {
    return list.map(fromProto).toList();
  }
}
