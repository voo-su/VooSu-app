import 'package:equatable/equatable.dart';
import 'package:voosu/domain/entities/user.dart';

class AuthState extends Equatable {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? error;
  final bool awaitingLoginCode;
  final String? pendingVerificationToken;
  final String? loginEmail;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
    this.awaitingLoginCode = false,
    this.pendingVerificationToken,
    this.loginEmail,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? error,
    bool? awaitingLoginCode,
    String? pendingVerificationToken,
    String? loginEmail,
    bool clearLoginCodeFlow = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
      awaitingLoginCode: clearLoginCodeFlow
          ? false
          : (awaitingLoginCode ?? this.awaitingLoginCode),
      pendingVerificationToken: clearLoginCodeFlow
          ? null
          : (pendingVerificationToken ?? this.pendingVerificationToken),
      loginEmail: clearLoginCodeFlow ? null : (loginEmail ?? this.loginEmail),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isAuthenticated,
    user,
    error,
    awaitingLoginCode,
    pendingVerificationToken,
    loginEmail,
  ];
}
