import 'package:equatable/equatable.dart';

class ContactListItem extends Equatable {
  final int id;
  final String username;
  final String name;
  final String surname;
  final String? photoId;

  const ContactListItem({
    required this.id,
    required this.username,
    required this.name,
    required this.surname,
    this.photoId,
  });

  String get displayLine {
    final n = '$name $surname'.trim();
    if (n.isNotEmpty) {
      return '$n · @$username';
    }
    return '@$username';
  }

  bool matchesQuery(String q) {
    final needle = q.trim().toLowerCase();
    if (needle.isEmpty) {
      return true;
    }
    return username.toLowerCase().contains(needle) ||
        name.toLowerCase().contains(needle) ||
        surname.toLowerCase().contains(needle);
  }

  @override
  List<Object?> get props => [id, username, name, surname, photoId];
}
