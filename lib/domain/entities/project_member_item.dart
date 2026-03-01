import 'package:equatable/equatable.dart';
import 'package:voosu/domain/entities/user.dart';

class ProjectMemberItem extends Equatable {
  final User user;
  final int role;

  const ProjectMemberItem({
    required this.user,
    required this.role,
  });

  bool get isAdmin => role == 1;

  @override
  List<Object?> get props => [user, role];
}
