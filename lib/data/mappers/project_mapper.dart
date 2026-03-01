import 'package:voosu/domain/entities/project.dart';
import 'package:voosu/domain/entities/project_member_item.dart';
import 'package:voosu/data/mappers/user_mapper.dart';
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

  static ProjectMemberItem memberItemFromProto(
    projectpb.ProjectMemberItem proto,
  ) {
    return ProjectMemberItem(
      user: UserMapper.fromProto(proto.user),
      role: proto.role,
    );
  }

  static List<ProjectMemberItem> memberListFromProto(
    Iterable<projectpb.ProjectMemberItem> list,
  ) {
    return list.map(memberItemFromProto).toList();
  }
}
