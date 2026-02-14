import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String username;
  final String name;
  final String surname;
  final int? avatarFileId;

  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.surname,
    this.avatarFileId,
  });

  User copyWith({int? avatarFileId}) {
    return User(
      id: id,
      username: username,
      name: name,
      surname: surname,
      avatarFileId: avatarFileId ?? this.avatarFileId,
    );
  }

  String get displayName {
    final n = '$name $surname'.trim();

    return n.isNotEmpty ? n : '@$username';
  }

  @override
  List<Object?> get props => [id, username, name, surname, avatarFileId];
}
