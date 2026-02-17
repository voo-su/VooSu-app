import 'package:get_it/get_it.dart';
import 'package:voosu/core/auth_guard.dart';
import 'package:voosu/data/db/app_database.dart';
import 'package:voosu/core/auth_interceptor.dart';
import 'package:voosu/core/grpc_channel_manager.dart';
import 'package:voosu/core/server_config.dart';
import 'package:voosu/data/data_sources/local/user_local_data_source.dart';
import 'package:voosu/data/data_sources/remote/account_remote_datasource.dart';
import 'package:voosu/data/data_sources/remote/auth_remote_datasource.dart';
import 'package:voosu/data/data_sources/remote/chat_remote_datasource.dart';
import 'package:voosu/data/data_sources/remote/search_remote_datasource.dart';
import 'package:voosu/data/repositories/account_repository_impl.dart';
import 'package:voosu/data/repositories/auth_repository_impl.dart';
import 'package:voosu/domain/repositories/account_repository.dart';
import 'package:voosu/domain/repositories/auth_repository.dart';
import 'package:voosu/domain/usecases/auth/refresh_token_usecase.dart';
import 'package:voosu/domain/usecases/chat/get_chats_usecase.dart';
import 'package:voosu/domain/usecases/chat/create_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/clear_chat_history_usecase.dart';
import 'package:voosu/domain/usecases/chat/delete_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/delete_chat_messages_usecase.dart';
import 'package:voosu/domain/usecases/chat/get_chat_messages_usecase.dart';
import 'package:voosu/domain/usecases/chat/get_pending_for_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/remove_pending_message_usecase.dart';
import 'package:voosu/domain/usecases/search/search_users_usecase.dart';
import 'package:voosu/presentation/screens/projects/project_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
  sl.registerLazySingleton<UserLocalDataSourceImpl>(
    () => UserLocalDataSourceImpl(db: sl<AppDatabase>()),
  );
  await sl<UserLocalDataSourceImpl>().init();

  sl.registerLazySingleton<ServerConfig>(() => ServerConfig());
  await sl<ServerConfig>().init();

  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(sl<UserLocalDataSourceImpl>()),
  );

  sl.registerLazySingleton<AuthGuard>(
    () => AuthGuard(() async {
      final storage = sl<UserLocalDataSourceImpl>();
      final refreshToken = storage.refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) return false;
      try {
        final tokens = await sl<RefreshTokenUseCase>()(refreshToken);
        storage.saveTokens(tokens.accessToken, tokens.refreshToken);
        return true;
      } catch (_) {
        return false;
      }
    }),
  );

  sl.registerLazySingleton<GrpcChannelManager>(
    () => GrpcChannelManager(sl<ServerConfig>(), sl<AuthInterceptor>()),
  );

  sl.registerLazySingleton<IAuthRemoteDataSource>(
    () => AuthRemoteDataSource(
      sl<GrpcChannelManager>(),
    ),
  );

  sl.registerLazySingleton<IAccountRemoteDataSource>(
    () => AccountRemoteDataSource(
      sl<GrpcChannelManager>(),
      sl<UserLocalDataSourceImpl>(),
    ),
  );

  sl.registerLazySingleton<IChatRemoteDataSource>(
    () => ChatRemoteDataSource(sl<GrpcChannelManager>(), sl<AuthGuard>()),
  );

  sl.registerLazySingleton<ISearchRemoteDataSource>(
    () => SearchRemoteDataSource(sl<GrpcChannelManager>(), sl<AuthGuard>()),
  );

  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl(sl()));
  sl.registerFactory(() => RefreshTokenUseCase(sl()));
  sl.registerFactory(() => SearchUsersUseCase(sl<ISearchRemoteDataSource>()));

  sl.registerFactory(() => GetChatsUseCase(sl<IChatRemoteDataSource>()));
  sl.registerFactory(() => CreateChatUseCase(sl<IChatRemoteDataSource>()));
  sl.registerFactory(() => GetChatMessagesUseCase(sl<IChatRemoteDataSource>()));
  sl.registerFactory(() => GetPendingForChatUseCase(sl<AppDatabase>()));
  sl.registerFactory(() => RemovePendingMessageUseCase(sl<AppDatabase>()));
  sl.registerFactory(() => DeleteChatMessagesUseCase(sl<IChatRemoteDataSource>()));
  sl.registerFactory(() => ClearChatHistoryUseCase(sl<IChatRemoteDataSource>()));
  sl.registerFactory(() => DeleteChatUseCase(sl<IChatRemoteDataSource>()));

  sl.registerFactory(
    () => ProjectCubit(
      sl<GrpcChannelManager>(),
      sl<AuthGuard>(),
    ),
  );

}
