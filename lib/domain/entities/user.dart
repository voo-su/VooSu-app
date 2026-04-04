import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String username;
  final String name;
  final String surname;
  final int gender;
  final String birthday;
  final String about;
  final String? photoId;
  final int messagePrivacy;

  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.surname,
    this.gender = 0,
    this.birthday = '',
    this.about = '',
    this.photoId,
    this.messagePrivacy = 0,
  });

  User copyWith({
    String? username,
    String? name,
    String? surname,
    int? gender,
    String? birthday,
    String? about,
    String? photoId,
    int? messagePrivacy,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      about: about ?? this.about,
      photoId: photoId ?? this.photoId,
      messagePrivacy: messagePrivacy ?? this.messagePrivacy,
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
    photoId,
    messagePrivacy,
  ];
}
