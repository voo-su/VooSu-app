import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String username;
  final String name;
  final String surname;
  final int gender;
  final String birthday;
  final String about;
  final int? avatarFileId;

  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.surname,
    this.gender = 0,
    this.birthday = '',
    this.about = '',
    this.avatarFileId,
  });

  User copyWith({
    String? username,
    String? name,
    String? surname,
    int? gender,
    String? birthday,
    String? about,
    int? avatarFileId,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      about: about ?? this.about,
      avatarFileId: avatarFileId ?? this.avatarFileId,
    );
  }

  String get displayName {
    final n = '$name $surname'.trim();

    return n.isNotEmpty ? n : '@$username';
  }

  @override
  List<Object?> get props => [
    id,
    username,
    name,
    surname,
    gender,
    birthday,
    about,
    avatarFileId,
  ];
}
