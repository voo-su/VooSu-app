import 'package:equatable/equatable.dart';

class OvertGroupListing extends Equatable {
  final int id;
  final int type;
  final String name;
  final String avatarUrl;
  final String description;
  final int memberCount;
  final int maxNum;
  final int createdAtSec;
  final bool isMember;

  const OvertGroupListing({
    required this.id,
    this.type = 1,
    required this.name,
    this.avatarUrl = '',
    this.description = '',
    this.memberCount = 0,
    this.maxNum = 200,
    this.createdAtSec = 0,
    this.isMember = false,
  });

  String get membersLabel => '$memberCount / $maxNum';

  @override
  List<Object?> get props => [
    id,
    type,
    name,
    avatarUrl,
    description,
    memberCount,
    maxNum,
    createdAtSec,
    isMember,
  ];
}
