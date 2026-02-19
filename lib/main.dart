import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:voosu/core/app_providers.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/core/router/app_router.dart';
import 'package:voosu/core/theme/app_theme.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_state.dart';
import 'package:voosu/presentation/screens/auth/login_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MultiBlocProvider(
      providers: AppProviders.allProviders,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState.isLoading && !authState.isAuthenticated) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'voosu',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: ThemeMode.system,
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
              themeMode: ThemeMode.system,
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
            themeMode: ThemeMode.system,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ru')],
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
