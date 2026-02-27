import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/data/data_sources/local/chat_notification_settings_local_data_source.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_event.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:voosu/presentation/screens/projects/project_cubit.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class AppProviders {
  static List<BlocProvider> get blocProviders => [
    BlocProvider<AuthBloc>(
      create: (context) => di.sl<AuthBloc>()..add(const AuthCheckRequested()),
    ),
    BlocProvider<ChatBloc>(create: (context) => di.sl<ChatBloc>()),
    BlocProvider<ProjectCubit>(create: (context) => di.sl<ProjectCubit>()),
  ];

  static List<SingleChildWidget> get allProviders => [
    Provider<ChatNotificationSettingsLocalDataSource>.value(
      value: di.sl<ChatNotificationSettingsLocalDataSource>(),
    ),
    ...blocProviders,
  ];
}
