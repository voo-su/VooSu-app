import 'package:voosu/domain/entities/user.dart';

class GroupInfo {
  final int id;
  final String title;
  final int memberCount;
  final int? avatarFileId;
  final List<GroupMemberInfo> members;
  final List<User> users;

  GroupInfo({
    required this.id,
    required this.title,
    required this.memberCount,
    this.avatarFileId,
    required this.members,
    required this.users,
  });

  Map<int, GroupMemberInfo> get memberByUserId => {
    for (final m in members) m.userId: m,
  };

  Map<int, User> get userById => {for (final u in users) u.id: u};
}

class GroupMemberInfo {
  final int userId;
  final int role;

  GroupMemberInfo({
    required this.userId,
    required this.role,
  });

  bool get isAdmin => role == 1;
}
