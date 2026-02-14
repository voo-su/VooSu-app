import 'package:get_it/get_it.dart';
import 'package:grpc/grpc.dart';
import 'package:voosu/core/app_server_constants.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/data_sources/remote/account_remote_datasource.dart';
import 'package:voosu/data/data_sources/remote/chat_remote_datasource.dart';
import 'package:voosu/data/data_sources/remote/search_remote_datasource.dart';
import 'package:voosu/data/repositories/account_repository_impl.dart';
import 'package:voosu/domain/repositories/account_repository.dart';
import 'package:voosu/domain/usecases/chat/get_chats_usecase.dart';
import 'package:voosu/domain/usecases/chat/create_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/clear_chat_history_usecase.dart';
import 'package:voosu/domain/usecases/chat/delete_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/delete_chat_messages_usecase.dart';
import 'package:voosu/domain/usecases/chat/get_chat_messages_usecase.dart';
import 'package:voosu/domain/usecases/chat/get_pending_for_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/remove_pending_message_usecase.dart';
import 'package:voosu/domain/usecases/search/search_users_usecase.dart';

final sl = GetIt.instance;

void init() {
  sl.registerLazySingleton<ClientChannel>(() {
    Logs().d(
      'gRPC: канал ${AppServerConstants.grpcHost}:${AppServerConstants.grpcPort}',
    );
    return ClientChannel(
      AppServerConstants.grpcHost,
      port: AppServerConstants.grpcPort,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
        idleTimeout: Duration(seconds: 30),
      ),
    );
  });

  sl.registerLazySingleton<IAccountRemoteDataSource>(
    () => AccountRemoteDataSource(sl<ClientChannel>()),
  );

  sl.registerLazySingleton<IChatRemoteDataSource>(
    () => ChatRemoteDataSource(sl<ClientChannel>()),
  );

  sl.registerLazySingleton<ISearchRemoteDataSource>(
    () => SearchRemoteDataSource(sl<ClientChannel>()),
  );

  sl.registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl(sl()));
  sl.registerFactory(() => SearchUsersUseCase(sl<ISearchRemoteDataSource>()));

  sl.registerFactory(() => GetChatsUseCase(sl<IChatRemoteDataSource>()));
  sl.registerFactory(() => CreateChatUseCase(sl<IChatRemoteDataSource>()));
  sl.registerFactory(() => GetChatMessagesUseCase(sl<IChatRemoteDataSource>()));
  sl.registerFactory(() => const GetPendingForChatUseCase());
  sl.registerFactory(() => const RemovePendingMessageUseCase());
  sl.registerFactory(() => DeleteChatMessagesUseCase(sl<IChatRemoteDataSource>()));
  sl.registerFactory(() => ClearChatHistoryUseCase(sl<IChatRemoteDataSource>()));
  sl.registerFactory(() => DeleteChatUseCase(sl<IChatRemoteDataSource>()));
}
