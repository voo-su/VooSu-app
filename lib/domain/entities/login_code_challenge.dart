import 'package:equatable/equatable.dart';

class LoginCodeChallenge extends Equatable {
  final String verificationToken;
  final int expiresInSec;

  const LoginCodeChallenge({
    required this.verificationToken,
    required this.expiresInSec,
  });

  @override
  List<Object?> get props => [verificationToken, expiresInSec];
}
