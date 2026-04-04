import 'package:equatable/equatable.dart';

class ContactUserProfile extends Equatable {
  final int id;
  final String username;
  final String? photoId;
  final String name;
  final String surname;
  final int gender;
  final String about;

  const ContactUserProfile({
    required this.id,
    required this.username,
    this.photoId,
    this.name = '',
    this.surname = '',
    this.gender = 0,
    this.about = '',
  });

  String get title {
    if (username.isNotEmpty) {
      return username;
    }
    final n = '$name $surname'.trim();
    if (n.isNotEmpty) {
      return n;
    }
    return 'Пользователь';
  }

  @override
  List<Object?> get props => [
    id,
    username,
    photoId,
    name,
    surname,
    gender,
    about,
  ];
}
