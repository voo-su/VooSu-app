import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/auth_guard.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/jwt_util.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/data_sources/local/chat_notification_settings_local_data_source.dart';
import 'package:voosu/data/data_sources/local/user_local_data_source.dart';
import 'package:voosu/data/services/pts_sync_service.dart';
import 'package:voosu/domain/usecases/auth/email_auth_usecases.dart';
import 'package:voosu/domain/usecases/auth/logout_usecase.dart';
import 'package:voosu/domain/usecases/auth/refresh_token_usecase.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_event.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RequestLoginCodeUseCase requestLoginCodeUseCase;
  final VerifyLoginUseCase verifyLoginUseCase;
  final RefreshTokenUseCase refreshTokenUseCase;
  final LogoutUseCase logoutUseCase;
  final UserLocalDataSourceImpl tokenStorage;
  final AuthGuard authGuard;
  final PtsSyncService? ptsSyncService;
  final ChatNotificationSettingsLocalDataSource? chatNotificationSettings;

  Timer? _backgroundRefreshTimer;

  AuthBloc({
    required this.requestLoginCodeUseCase,
    required this.verifyLoginUseCase,
    required this.refreshTokenUseCase,
    required this.logoutUseCase,
    required this.tokenStorage,
    required this.authGuard,
    this.ptsSyncService,
    this.chatNotificationSettings,
  }) : super(const AuthState()) {
    authGuard.setOnSessionExpired(() => add(const AuthLogoutRequested()));
    on<AuthLoginCodeRequested>(_onLoginCodeRequested);
    on<AuthResendLoginCodeRequested>(_onResendLoginCodeRequested);
    on<AuthLoginVerifyRequested>(_onLoginVerifyRequested);
    on<AuthBackToEmailLogin>(_onBackToEmailLogin);
    on<AuthRefreshTokenRequested>(_onRefreshTokenRequested);
    on<AuthRefreshTokenInBackground>(_onRefreshTokenInBackground);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthClearError>(_onClearError);
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthProfilePhotoUpdated>(_onProfilePhotoUpdated);
  }

  @override
  void onTransition(Transition<AuthEvent, AuthState> transition) {
    super.onTransition(transition);
    if (transition.nextState.isAuthenticated) {
      _startBackgroundRefreshTimer();
      ptsSyncService?.startSync();
      chatNotificationSettings?.ensureLoaded();
    } else {
      _cancelBackgroundRefreshTimer();
      ptsSyncService?.stopSync();
    }
  }

  @override
  Future<void> close() {
    _cancelBackgroundRefreshTimer();
    return super.close();
  }

  void _startBackgroundRefreshTimer() {
    _cancelBackgroundRefreshTimer();
    _backgroundRefreshTimer = Timer.periodic(backgroundRefreshCheckInterval, (
      _,
    ) {
      final expiry = getAccessTokenExpiry(tokenStorage.accessToken);
      if (expiry == null) return;
      final now = DateTime.now();
      if (expiry.difference(now) <= accessTokenRefreshThreshold) {
        Logs().d(
          'AuthBloc: время access-токена подходит к концу - фоновый рефреш',
        );
        add(const AuthRefreshTokenInBackground());
      }
    });
  }

  void _cancelBackgroundRefreshTimer() {
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = null;
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    Logs().d('AuthBloc: проверка авторизации');
    emit(state.copyWith(isLoading: true, error: null));

    final refreshToken = tokenStorage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      Logs().i('AuthBloc: токен отсутствует, пользователь не авторизован');
      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
          error: null,
        ),
      );
      return;
    }

    const maxAttempts = 3;
    const retryDelay = Duration(milliseconds: 1500);

    Object? lastError;
    var wasUnauthorized = false;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final tokens = await refreshTokenUseCase(refreshToken);
        tokenStorage.saveTokens(tokens.accessToken, tokens.refreshToken);
        final user = tokenStorage.user;

        if (user == null) {
          tokenStorage.clearTokens();
          emit(
            state.copyWith(
              isLoading: false,
              isAuthenticated: false,
              user: null,
              error: null,
            ),
          );
          return;
        }

        Logs().i('AuthBloc: проверка авторизации успешна');
        emit(
          state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            user: user,
            error: null,
          ),
        );
        return;
      } catch (e) {
        lastError = e;
        wasUnauthorized = e is UnauthorizedFailure;
        if (wasUnauthorized) {
          Logs().w('AuthBloc: неавторизован при проверке токена');
          break;
        }
        Logs().w(
          'AuthBloc: ошибка при проверке токена, попытка ${attempt + 1}/$maxAttempts',
          e,
        );
        if (attempt < maxAttempts) {
          await Future<void>.delayed(retryDelay);
        }
      }
    }

    if (wasUnauthorized) {
      tokenStorage.clearTokens();
      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
          error: null,
        ),
      );
    } else {
      final user = tokenStorage.user;
      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
          error: lastError?.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onLoginCodeRequested(
    AuthLoginCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    Logs().i('AuthBloc: запрос кода для ${event.email}');
    emit(
      state.copyWith(
        isLoading: true,
        error: null,
        clearLoginCodeFlow: true,
      ),
    );

    try {
      final challenge = await requestLoginCodeUseCase(event.email);
      emit(
        state.copyWith(
          isLoading: false,
          pendingVerificationToken: challenge.verificationToken,
          loginEmail: event.email,
          awaitingLoginCode: true,
          error: null,
        ),
      );
    } catch (e) {
      Logs().e('AuthBloc: ошибка отправки кода', e);
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onResendLoginCodeRequested(
    AuthResendLoginCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    final email = state.loginEmail;
    if (email == null || email.isEmpty) {
      emit(
        state.copyWith(
          error: 'Сначала укажите email',
          isLoading: false,
        ),
      );
      return;
    }

    Logs().i('AuthBloc: повторная отправка кода для $email');
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final challenge = await requestLoginCodeUseCase(email);
      emit(
        state.copyWith(
          isLoading: false,
          pendingVerificationToken: challenge.verificationToken,
          loginEmail: email,
          awaitingLoginCode: true,
          error: null,
        ),
      );
    } catch (e) {
      Logs().e('AuthBloc: ошибка повторной отправки кода', e);
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onLoginVerifyRequested(
    AuthLoginVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    final token = state.pendingVerificationToken;
    if (token == null || token.isEmpty) {
      emit(
        state.copyWith(
          error: 'Сначала запросите код на почту',
          isLoading: false,
        ),
      );
      return;
    }

    Logs().d('AuthBloc: проверка кода');
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final result = await verifyLoginUseCase(token, event.code);

      tokenStorage.saveTokens(
        result.tokens.accessToken,
        result.tokens.refreshToken,
      );
      tokenStorage.saveUser(result.user);

      Logs().i('AuthBloc: вход выполнен успешно');
      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: result.user,
          error: null,
          clearLoginCodeFlow: true,
        ),
      );
    } catch (e) {
      Logs().e('AuthBloc: ошибка входа', e);
      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          error: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  void _onBackToEmailLogin(
    AuthBackToEmailLogin event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(clearLoginCodeFlow: true, error: null));
  }

  Future<void> _onRefreshTokenRequested(
    AuthRefreshTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    Logs().d('AuthBloc: обновление токена');
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final tokens = await refreshTokenUseCase(event.refreshToken);

      tokenStorage.saveTokens(tokens.accessToken, tokens.refreshToken);

      Logs().i('AuthBloc: токен обновлён');
      emit(state.copyWith(isLoading: false, error: null));
    } catch (e) {
      if (e is UnauthorizedFailure) {
        Logs().w('AuthBloc: недействительный refresh token');
        tokenStorage.clearTokens();
        emit(
          state.copyWith(
            isLoading: false,
            isAuthenticated: false,
            user: null,
            error: e.toString().replaceAll('Exception: ', ''),
          ),
        );
      } else {
        Logs().e('AuthBloc: ошибка обновления токена', e);
        emit(
          state.copyWith(
            isLoading: false,
            error: e.toString().replaceAll('Exception: ', ''),
          ),
        );
      }
    }
  }

  Future<void> _onRefreshTokenInBackground(
    AuthRefreshTokenInBackground event,
    Emitter<AuthState> emit,
  ) async {
    final refreshToken = tokenStorage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return;

    try {
      final tokens = await refreshTokenUseCase(refreshToken);
      tokenStorage.saveTokens(tokens.accessToken, tokens.refreshToken);
      Logs().d('AuthBloc: фоновый рефреш токена выполнен');
    } catch (e) {
      if (e is UnauthorizedFailure) {
        Logs().w(
          'AuthBloc: недействительный refresh token при фоновом рефреше',
        );
        tokenStorage.clearTokens();
        emit(
          state.copyWith(
            isLoading: false,
            isAuthenticated: false,
            user: null,
            error: null,
          ),
        );
      }
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    Logs().i('AuthBloc: выход');
    emit(state.copyWith(isLoading: true, error: null));

    try {
      await logoutUseCase();
      Logs().i('AuthBloc: выход выполнен');
    } catch (e) {
      Logs().w('AuthBloc: ошибка при выходе на сервере (токены очищены)', e);
    } finally {
      tokenStorage.clearTokens();
      await ptsSyncService?.stopSync();
      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
          error: null,
        ),
      );
    }
  }

  void _onClearError(AuthClearError event, Emitter<AuthState> emit) {
    emit(state.copyWith(error: null));
  }

  void _onProfilePhotoUpdated(
    AuthProfilePhotoUpdated event,
    Emitter<AuthState> emit,
  ) {
    final u = state.user;
    if (u == null) return;
    final newUser = u.copyWith(avatarFileId: event.avatarFileId);
    tokenStorage.saveUser(newUser);
    emit(state.copyWith(user: newUser));
  }
}
