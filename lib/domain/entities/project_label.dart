import 'package:equatable/equatable.dart';

class ProjectLabel extends Equatable {
  final int id;
  final String name;
  final String color;

  const ProjectLabel({
    required this.id,
    required this.name,
    this.color = '#9E9E9E',
  });

  @override
  List<Object?> get props => [id, name, color];
}
