import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginCodeRequested extends AuthEvent {
  final String email;

  const AuthLoginCodeRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthResendLoginCodeRequested extends AuthEvent {
  const AuthResendLoginCodeRequested();
}

class AuthLoginVerifyRequested extends AuthEvent {
  final String code;

  const AuthLoginVerifyRequested(this.code);

  @override
  List<Object?> get props => [code];
}

class AuthBackToEmailLogin extends AuthEvent {
  const AuthBackToEmailLogin();
}

class AuthRefreshTokenRequested extends AuthEvent {
  final String refreshToken;

  const AuthRefreshTokenRequested(this.refreshToken);

  @override
  List<Object?> get props => [refreshToken];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthClearError extends AuthEvent {
  const AuthClearError();
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthRefreshTokenInBackground extends AuthEvent {
  const AuthRefreshTokenInBackground();
}

class AuthClearNeedsUpdate extends AuthEvent {
  const AuthClearNeedsUpdate();
}

class AuthProfilePhotoUpdated extends AuthEvent {
  final int avatarFileId;
  final List<int>? imageBytes;

  const AuthProfilePhotoUpdated(this.avatarFileId, [this.imageBytes]);

  @override
  List<Object?> get props => [avatarFileId, imageBytes];
}

class AuthUsernameUpdated extends AuthEvent {
  final String username;

  const AuthUsernameUpdated(this.username);

  @override
  List<Object?> get props => [username];
}

class AuthProfilePersonalUpdated extends AuthEvent {
  final String name;
  final String surname;
  final int gender;
  final String birthday;
  final String about;

  const AuthProfilePersonalUpdated({
    required this.name,
    required this.surname,
    required this.gender,
    required this.birthday,
    required this.about,
  });

  @override
  List<Object?> get props => [name, surname, gender, birthday, about];
}
