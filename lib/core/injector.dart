import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:voosu/core/auth_guard.dart';
import 'package:voosu/data/db/app_database.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/entities/user_typing_payload.dart';
import 'package:voosu/domain/entities/message_deleted_payload.dart';
import 'package:voosu/domain/entities/message_read_payload.dart';
import 'package:voosu/domain/entities/task_update_payload.dart';
import 'package:voosu/core/auth_interceptor.dart';
import 'package:voosu/core/grpc_channel_manager.dart';
import 'package:voosu/core/connection_status.dart';
import 'package:voosu/core/server_config.dart';
import 'package:voosu/data/services/user_online_status_service.dart';
import 'package:voosu/data/data_sources/local/user_local_data_source.dart';
import 'package:voosu/data/data_sources/remote/account_remote_datasource.dart';
import 'package:voosu/data/data_sources/remote/auth_remote_datasource.dart';
import 'package:voosu/data/data_sources/remote/chat_remote_datasource.dart';
import 'package:voosu/data/data_sources/remote/project_remote_datasource.dart';
import 'package:voosu/data/data_sources/remote/contact_remote_datasource.dart';
import 'package:voosu/data/data_sources/remote/search_remote_datasource.dart';
import 'package:voosu/data/repositories/contact_repository_impl.dart';
import 'package:voosu/data/repositories/account_repository_impl.dart';
import 'package:voosu/data/repositories/auth_repository_impl.dart';
import 'package:voosu/data/repositories/project_repository_impl.dart';
import 'package:voosu/data/repositories/user_chat_repository_impl.dart';
import 'package:voosu/data/data_sources/local/chat_draft_local_data_source.dart';
import 'package:voosu/data/data_sources/local/chat_notification_settings_local_data_source.dart';
import 'package:voosu/data/services/notification_sound_service.dart';
import 'package:voosu/data/services/media_cache_service.dart';
import 'package:voosu/data/services/upload_queue_service.dart';
import 'package:voosu/data/services/pts_sync_service.dart';
import 'package:voosu/domain/repositories/account_repository.dart';
import 'package:voosu/domain/repositories/auth_repository.dart';
import 'package:voosu/domain/repositories/project_repository.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';
import 'package:voosu/domain/repositories/contact_repository.dart';
import 'package:voosu/domain/usecases/account/change_username_usecase.dart';
import 'package:voosu/domain/usecases/account/get_confidentiality_settings_usecase.dart';
import 'package:voosu/domain/usecases/account/get_devices_usecase.dart';
import 'package:voosu/domain/usecases/account/update_confidentiality_settings_usecase.dart';
import 'package:voosu/domain/usecases/account/request_email_change_usecase.dart';
import 'package:voosu/domain/usecases/account/update_profile_personal_usecase.dart';
import 'package:voosu/domain/usecases/account/verify_email_change_usecase.dart';
import 'package:voosu/domain/usecases/auth/email_auth_usecases.dart';
import 'package:voosu/domain/usecases/auth/logout_usecase.dart';
import 'package:voosu/domain/usecases/auth/refresh_token_usecase.dart';
import 'package:voosu/domain/usecases/account/revoke_device_usecase.dart';
import 'package:voosu/domain/usecases/project/add_user_to_project_usecase.dart';
import 'package:voosu/domain/usecases/project/create_project_usecase.dart';
import 'package:voosu/domain/usecases/project/create_task_usecase.dart';
import 'package:voosu/domain/usecases/project/get_project_members_usecase.dart';
import 'package:voosu/domain/usecases/project/get_project_usecase.dart';
import 'package:voosu/domain/usecases/project/get_projects_usecase.dart';
import 'package:voosu/domain/usecases/project/remove_user_from_project_usecase.dart';
import 'package:voosu/domain/usecases/project/update_project_usecase.dart';
import 'package:voosu/domain/usecases/project/get_task_usecase.dart';
import 'package:voosu/domain/usecases/project/get_tasks_usecase.dart';
import 'package:voosu/domain/usecases/project/edit_task_column_id_usecase.dart';
import 'package:voosu/domain/usecases/project/edit_task_usecase.dart';
import 'package:voosu/domain/usecases/project/delete_task_usecase.dart';
import 'package:voosu/domain/usecases/project/get_task_comments_usecase.dart';
import 'package:voosu/domain/usecases/project/add_task_comment_usecase.dart';
import 'package:voosu/domain/usecases/project/get_project_columns_usecase.dart';
import 'package:voosu/domain/usecases/project/create_project_column_usecase.dart';
import 'package:voosu/domain/usecases/project/edit_project_column_usecase.dart';
import 'package:voosu/domain/usecases/project/delete_project_column_usecase.dart';
import 'package:voosu/domain/usecases/project/get_project_labels_usecase.dart';
import 'package:voosu/domain/usecases/project/create_project_label_usecase.dart';
import 'package:voosu/domain/usecases/project/update_project_label_usecase.dart';
import 'package:voosu/domain/usecases/project/delete_project_label_usecase.dart';
import 'package:voosu/domain/usecases/project/get_project_history_usecase.dart';
import 'package:voosu/domain/usecases/project/get_task_history_usecase.dart';
import 'package:voosu/domain/usecases/chat/get_chats_usecase.dart';
import 'package:voosu/domain/usecases/chat/create_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/create_group_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/clear_chat_history_usecase.dart';
import 'package:voosu/domain/usecases/chat/delete_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/delete_chat_messages_usecase.dart';
import 'package:voosu/domain/usecases/chat/get_chat_messages_usecase.dart';
import 'package:voosu/domain/usecases/chat/get_group_mention_members_usecase.dart';
import 'package:voosu/domain/usecases/chat/get_pending_for_chat_usecase.dart';
import 'package:voosu/domain/usecases/chat/remove_pending_message_usecase.dart';
import 'package:voosu/domain/usecases/chat/request_group_join_usecase.dart';
import 'package:voosu/domain/usecases/chat/search_public_groups_usecase.dart';
import 'package:voosu/domain/usecases/chat/save_pending_message_usecase.dart';
import 'package:voosu/domain/usecases/chat/add_sticker_from_uploaded_file_usecase.dart';
import 'package:voosu/domain/usecases/chat/collect_sticker_from_message_usecase.dart';
import 'package:voosu/domain/usecases/chat/delete_my_stickers_usecase.dart';
import 'package:voosu/domain/usecases/chat/list_my_stickers_usecase.dart';
import 'package:voosu/domain/usecases/chat/send_chat_message_usecase.dart';
import 'package:voosu/domain/usecases/chat/send_chat_code_usecase.dart';
import 'package:voosu/domain/usecases/chat/send_chat_location_usecase.dart';
import 'package:voosu/domain/usecases/chat/send_chat_sticker_usecase.dart';
import 'package:voosu/domain/usecases/chat/upload_chat_file_usecase.dart';
import 'package:voosu/domain/usecases/chat/send_chat_typing_usecase.dart';
import 'package:voosu/domain/usecases/chat/report_inline_callback_usecase.dart';
import 'package:voosu/domain/usecases/chat/chat_poll_usecase.dart';
import 'package:voosu/domain/usecases/chat/set_chat_notifications_usecase.dart';
import 'package:voosu/domain/usecases/chat/set_chat_pin_usecase.dart';
import 'package:voosu/domain/usecases/chat/leave_group_usecase.dart';
import 'package:voosu/domain/usecases/chat/clear_unread_chat_usecase.dart';
import 'package:voosu/domain/usecases/contact/get_contact_user_usecase.dart';
import 'package:voosu/domain/usecases/contact/get_contacts_usecase.dart';
import 'package:voosu/domain/usecases/search/search_users_usecase.dart';
import 'package:voosu/presentation/cubit/theme/theme_cubit.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:voosu/presentation/screens/chat/bloc/chat_bloc.dart';
import 'package:voosu/presentation/screens/devices/bloc/devices_bloc.dart';
import 'package:voosu/presentation/screens/projects/bloc/project_bloc.dart';
import 'package:voosu/presentation/screens/tasks/bloc/task_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
  sl.registerLazySingleton<UserLocalDataSourceImpl>(
    () => UserLocalDataSourceImpl(db: sl<AppDatabase>()),
  );
  sl.registerLazySingleton<UserLocalDataSource>(
    () => sl<UserLocalDataSourceImpl>(),
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

  sl.registerLazySingleton<ConnectionStatusService>(
    () => ConnectionStatusService(),
  );

  sl.registerLazySingleton<UserOnlineStatusService>(
    () => UserOnlineStatusService(),
  );

  sl.registerLazySingleton<StreamController<Message>>(
    () => StreamController<Message>.broadcast(),
  );

  sl.registerLazySingleton<StreamController<MessageDeletedPayload>>(
    () => StreamController<MessageDeletedPayload>.broadcast(),
  );

  sl.registerLazySingleton<StreamController<MessageReadPayload>>(
    () => StreamController<MessageReadPayload>.broadcast(),
  );

  sl.registerLazySingleton<StreamController<UserTypingPayload>>(
    () => StreamController<UserTypingPayload>.broadcast(),
  );

  sl.registerLazySingleton<StreamController<TaskUpdatePayload>>(
    () => StreamController<TaskUpdatePayload>.broadcast(),
  );

  sl.registerLazySingleton<StreamController<Object?>>(
    () => StreamController<Object?>.broadcast(),
  );

  sl.registerLazySingleton<StreamController<Object?>>(
    instanceName: 'syncRestored',
    () => StreamController<Object?>.broadcast(),
  );

  sl.registerLazySingleton<NotificationSoundService>(
    () => NotificationSoundService(sl<UserLocalDataSource>()),
  );

  sl.registerLazySingleton<MediaCacheService>(
    () => MediaCacheService(sl<AccountRepository>()),
  );

  sl.registerLazySingleton<ChatNotificationSettingsLocalDataSource>(
    () => ChatNotificationSettingsLocalDataSourceImpl(),
  );

  final chatDraftLocalDataSource = ChatDraftLocalDataSource();
  await chatDraftLocalDataSource.hydrate();
  sl.registerSingleton<ChatDraftLocalDataSource>(chatDraftLocalDataSource);

  sl.registerLazySingleton<PtsSyncService>(
    () => PtsSyncService(
      sl<IAccountRemoteDataSource>(),
      sl<UserLocalDataSourceImpl>(),
      sl<GetChatsUseCase>(),
      sl<ConnectionStatusService>(),
      getChatMessagesUseCase: sl<GetChatMessagesUseCase>(),
      chatRepository: sl<ChatRepository>(),
      cacheDb: sl<AppDatabase>(),
      userOnlineStatusService: sl<UserOnlineStatusService>(),
      newMessageSink: sl<StreamController<Message>>().sink,
      messageDeletedSink: sl<StreamController<MessageDeletedPayload>>().sink,
      messageReadSink: sl<StreamController<MessageReadPayload>>().sink,
      userTypingSink: sl<StreamController<UserTypingPayload>>().sink,
      taskUpdateSink: sl<StreamController<TaskUpdatePayload>>().sink,
      chatListRefreshSink: sl<StreamController<Object?>>().sink,
      syncRestoredSink: sl<StreamController<Object?>>(instanceName: 'syncRestored').sink,
    ),
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
      sl<ConnectionStatusService>(),
    ),
  );

  sl.registerLazySingleton<IChatRemoteDataSource>(
    () => ChatRemoteDataSource(sl<GrpcChannelManager>(), sl<AuthGuard>()),
  );

  sl.registerLazySingleton<ISearchRemoteDataSource>(
    () => SearchRemoteDataSource(sl<GrpcChannelManager>(), sl<AuthGuard>()),
  );

  sl.registerLazySingleton<IContactRemoteDataSource>(
    () => ContactRemoteDataSource(sl<GrpcChannelManager>(), sl<AuthGuard>()),
  );

  sl.registerLazySingleton<IProjectRemoteDataSource>(
    () => ProjectRemoteDataSource(sl<GrpcChannelManager>(), sl<AuthGuard>()),
  );

  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl(sl()));
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(sl<IChatRemoteDataSource>(), sl<AppDatabase>()),
  );
  sl.registerLazySingleton<ProjectRepository>(
    () => ProjectRepositoryImpl(sl<IProjectRemoteDataSource>()),
  );
  sl.registerLazySingleton<ContactRepository>(
    () => ContactRepositoryImpl(sl<IContactRemoteDataSource>()),
  );

  sl.registerLazySingleton<UploadQueueService>(() => UploadQueueService());

  sl.registerFactory(() => RequestLoginCodeUseCase(sl()));
  sl.registerFactory(() => VerifyLoginUseCase(sl()));
  sl.registerFactory(() => RefreshTokenUseCase(sl()));
  sl.registerFactory(() => LogoutUseCase(sl()));
  sl.registerFactory(() => ChangeUsernameUseCase(sl()));
  sl.registerFactory(() => UpdateProfilePersonalUseCase(sl()));
  sl.registerFactory(() => RequestEmailChangeUseCase(sl()));
  sl.registerFactory(() => VerifyEmailChangeUseCase(sl()));
  sl.registerFactory(() => GetDevicesUseCase(sl()));
  sl.registerFactory(() => RevokeDeviceUseCase(sl()));
  sl.registerFactory(() => GetConfidentialitySettingsUseCase(sl()));
  sl.registerFactory(() => UpdateConfidentialitySettingsUseCase(sl()));

  sl.registerFactory(() => SearchUsersUseCase(sl<ISearchRemoteDataSource>()));
  sl.registerFactory(() => GetContactsUseCase(sl<ContactRepository>()));
  sl.registerFactory(() => GetContactUserUseCase(sl<ContactRepository>()));

  sl.registerFactory(() => CreateProjectUseCase(sl()));
  sl.registerFactory(() => GetProjectsUseCase(sl()));
  sl.registerFactory(() => GetProjectUseCase(sl()));
  sl.registerFactory(() => AddUserToProjectUseCase(sl()));
  sl.registerFactory(() => GetProjectMembersUseCase(sl()));
  sl.registerFactory(() => UpdateProjectUseCase(sl()));
  sl.registerFactory(() => RemoveUserFromProjectUseCase(sl()));
  sl.registerFactory(() => CreateTaskUseCase(sl()));
  sl.registerFactory(() => GetTasksUseCase(sl()));
  sl.registerFactory(() => GetTaskUseCase(sl()));
  sl.registerFactory(() => EditTaskColumnIdUseCase(sl()));
  sl.registerFactory(() => EditTaskUseCase(sl()));
  sl.registerFactory(() => DeleteTaskUseCase(sl()));
  sl.registerFactory(() => GetTaskCommentsUseCase(sl()));
  sl.registerFactory(() => AddTaskCommentUseCase(sl()));
  sl.registerFactory(() => GetProjectColumnsUseCase(sl()));
  sl.registerFactory(() => CreateProjectColumnUseCase(sl()));
  sl.registerFactory(() => EditProjectColumnUseCase(sl()));
  sl.registerFactory(() => DeleteProjectColumnUseCase(sl()));
  sl.registerFactory(() => GetProjectLabelsUseCase(sl()));
  sl.registerFactory(() => CreateProjectLabelUseCase(sl()));
  sl.registerFactory(() => UpdateProjectLabelUseCase(sl()));
  sl.registerFactory(() => DeleteProjectLabelUseCase(sl()));
  sl.registerFactory(() => GetProjectHistoryUseCase(sl()));
  sl.registerFactory(() => GetTaskHistoryUseCase(sl()));
  sl.registerFactory(() => GetChatsUseCase(sl()));
  sl.registerFactory(() => CreateChatUseCase(sl()));
  sl.registerFactory(() => CreateGroupChatUseCase(sl()));
  sl.registerFactory(() => GetChatMessagesUseCase(sl()));
  sl.registerFactory(() => SendChatMessageUseCase(sl()));
  sl.registerFactory(() => SendChatStickerUseCase(sl()));
  sl.registerFactory(() => SendChatCodeUseCase(sl()));
  sl.registerFactory(() => SendChatLocationUseCase(sl()));
  sl.registerFactory(() => ListMyStickersUseCase(sl()));
  sl.registerFactory(() => AddStickerFromUploadedFileUseCase(sl()));
  sl.registerFactory(() => DeleteMyStickersUseCase(sl()));
  sl.registerFactory(() => CollectStickerFromMessageUseCase(sl()));
  sl.registerFactory(() => SavePendingMessageUseCase(sl()));
  sl.registerFactory(() => GetPendingForChatUseCase(sl()));
  sl.registerFactory(() => GetGroupMentionMembersUseCase(sl()));
  sl.registerFactory(() => RemovePendingMessageUseCase(sl()));
  sl.registerFactory(
    () => UploadChatFileUseCase(sl<ChatRepository>(), sl<UploadQueueService>()),
  );
  sl.registerFactory(() => SendChatTypingUseCase(sl()));
  sl.registerFactory(() => DeleteChatMessagesUseCase(sl()));
  sl.registerFactory(() => ClearChatHistoryUseCase(sl()));
  sl.registerFactory(() => DeleteChatUseCase(sl()));
  sl.registerFactory(() => SetChatNotificationsUseCase(sl()));
  sl.registerFactory(() => SetChatPinUseCase(sl()));
  sl.registerFactory(() => LeaveGroupUseCase(sl()));
  sl.registerFactory(() => ClearUnreadChatUseCase(sl()));
  sl.registerFactory(() => SearchPublicGroupsUseCase(sl<ChatRepository>()));
  sl.registerFactory(() => RequestGroupJoinUseCase(sl<ChatRepository>()));
  sl.registerFactory(() => ReportInlineCallbackUseCase(sl()));
  sl.registerFactory(() => ChatPollUseCase(sl()));

  sl.registerFactory(
    () => ChatBloc(
      getChatsUseCase: sl(),
      createChatUseCase: sl(),
      createGroupChatUseCase: sl(),
      getChatMessagesUseCase: sl(),
      sendChatMessageUseCase: sl(),
      sendChatStickerUseCase: sl<SendChatStickerUseCase>(),
      sendChatCodeUseCase: sl<SendChatCodeUseCase>(),
      sendChatLocationUseCase: sl<SendChatLocationUseCase>(),
      savePendingMessageUseCase: sl(),
      getPendingForChatUseCase: sl(),
      getGroupMentionMembersUseCase: sl(),
      removePendingMessageUseCase: sl(),
      deleteChatMessagesUseCase: sl(),
      clearChatHistoryUseCase: sl(),
      deleteChatUseCase: sl(),
      authBloc: sl<AuthBloc>(),
      notificationSoundService: sl<NotificationSoundService>(),
      chatNotificationSettings: sl<ChatNotificationSettingsLocalDataSource>(),
      newMessageStream: sl<StreamController<Message>>().stream,
      messageDeletedStream: sl<StreamController<MessageDeletedPayload>>().stream,
      messageReadStream: sl<StreamController<MessageReadPayload>>().stream,
      userTypingStream: sl<StreamController<UserTypingPayload>>().stream,
      chatListRefreshStream: sl<StreamController<Object?>>().stream,
      syncRestoredStream: sl<StreamController<Object?>>(instanceName: 'syncRestored').stream,
      sendChatTypingUseCase: sl<SendChatTypingUseCase>(),
      setChatNotificationsUseCase: sl<SetChatNotificationsUseCase>(),
      setChatPinUseCase: sl<SetChatPinUseCase>(),
      leaveGroupUseCase: sl<LeaveGroupUseCase>(),
      clearUnreadChatUseCase: sl<ClearUnreadChatUseCase>(),
      collectStickerFromMessageUseCase: sl<CollectStickerFromMessageUseCase>(),
      reportInlineCallbackUseCase: sl<ReportInlineCallbackUseCase>(),
      chatPollUseCase: sl<ChatPollUseCase>(),
      chatDraftLocal: sl<ChatDraftLocalDataSource>(),
    ),
  );

  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      requestLoginCodeUseCase: sl(),
      verifyLoginUseCase: sl(),
      refreshTokenUseCase: sl(),
      logoutUseCase: sl(),
      tokenStorage: sl<UserLocalDataSourceImpl>(),
      channelManager: sl(),
      authGuard: sl<AuthGuard>(),
      ptsSyncService: sl<PtsSyncService>(),
      chatNotificationSettings: sl<ChatNotificationSettingsLocalDataSource>(),
      getConfidentialitySettingsUseCase: sl<GetConfidentialitySettingsUseCase>(),
      uploadQueueService: sl<UploadQueueService>(),
    ),
  );

  sl.registerFactory(
    () => DevicesBloc(getDevicesUseCase: sl(), revokeDeviceUseCase: sl()),
  );

  sl.registerFactory(
    () => ProjectBloc(
      getProjectsUseCase: sl(),
      createProjectUseCase: sl(),
      getProjectUseCase: sl(),
      getProjectMembersUseCase: sl(),
      addUserToProjectUseCase: sl(),
      updateProjectUseCase: sl(),
      removeUserFromProjectUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => TaskBloc(
      getTasksUseCase: sl(),
      createTaskUseCase: sl(),
      editTaskColumnIdUseCase: sl(),
      editTaskUseCase: sl(),
      deleteTaskUseCase: sl(),
    ),
  );

  sl.registerFactory(() => ThemeCubit(sl<UserLocalDataSourceImpl>()));
}
