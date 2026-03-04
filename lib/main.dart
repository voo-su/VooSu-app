import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:media_kit/media_kit.dart';
import 'package:voosu/core/app_providers.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/core/router/app_router.dart';
import 'package:voosu/core/theme/app_theme.dart';
import 'package:voosu/presentation/cubit/theme/theme_cubit.dart';
import 'package:voosu/presentation/cubit/theme/theme_state.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_state.dart';
import 'package:voosu/presentation/screens/auth/login_screen.dart';
import 'package:voosu/presentation/screens/auth/update_required_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  JustAudioMediaKit.ensureInitialized();
  Logs().i('Запуск приложения');
  await di.init();
  Logs().i('Инициализация завершена');
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ThemeCubit>(),
      child: MultiBlocProvider(
        providers: AppProviders.allProviders,
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            return BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, themeState) {
                if (authState.needsUpdate) {
                  return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    title: 'voosu',
                    theme: AppTheme.light,
                    darkTheme: AppTheme.dark,
                    themeMode: themeState.themeMode,
                    localizationsDelegates: const [
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: const [Locale('ru')],
                    home: const UpdateRequiredScreen(),
                  );
                }

                if (authState.isLoading && !authState.isAuthenticated) {
                  return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    title: 'voosu',
                    theme: AppTheme.light,
                    darkTheme: AppTheme.dark,
                    themeMode: themeState.themeMode,
                    localizationsDelegates: const [
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: const [Locale('ru')],
                    home: const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (authState.isAuthenticated) {
                  return MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    title: 'voosu',
                    theme: AppTheme.light,
                    darkTheme: AppTheme.dark,
                    themeMode: themeState.themeMode,
                    localizationsDelegates: const [
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: const [Locale('ru')],
                    routerConfig: _router,
                  );
                }

                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'voosu',
                  theme: AppTheme.light,
                  darkTheme: AppTheme.dark,
                  themeMode: themeState.themeMode,
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [Locale('ru')],
                  home: const LoginScreen(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
