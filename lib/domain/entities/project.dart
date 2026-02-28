import 'package:equatable/equatable.dart';

class Project extends Equatable {
  final int id;
  final String name;
  final int? currentUserRole;

  const Project({
    required this.id,
    required this.name,
    this.currentUserRole,
  });

  bool get isCurrentUserAdmin => currentUserRole == 1;

  @override
  List<Object?> get props => [id, name, currentUserRole];
}
