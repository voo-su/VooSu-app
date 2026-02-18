import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:voosu/core/app_providers.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/core/theme/app_theme.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_state.dart';
import 'package:voosu/presentation/screens/auth/login_screen.dart';
import 'package:voosu/presentation/screens/chat/chat_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logs().i('Запуск приложения');
  await di.init();
  Logs().i('Инициализация завершена');
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: AppProviders.allProviders,
      child: MaterialApp(
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
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState.isLoading && !authState.isAuthenticated) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (authState.isAuthenticated) {
              return const UserChatScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
