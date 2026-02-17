import 'package:grpc/grpc.dart';
import 'package:voosu/core/auth_interceptor.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/core/server_config.dart';
import 'package:voosu/generated/grpc_pb/auth.pbgrpc.dart' as authpb;
import 'package:voosu/generated/grpc_pb/chat.pbgrpc.dart' as chatpb;
import 'package:voosu/generated/grpc_pb/project.pbgrpc.dart' as projectpb;
import 'package:voosu/generated/grpc_pb/search.pbgrpc.dart' as searchpb;
import 'package:voosu/generated/grpc_pb/account.pbgrpc.dart' as accountpb;
import 'package:voosu/generated/grpc_pb/file.pbgrpc.dart' as filepb;

class GrpcChannelManager {
  final ServerConfig _config;
  final AuthInterceptor _authInterceptor;

  ClientChannel? _channel;
  authpb.AuthServiceClient? _authClient;
  accountpb.AccountServiceClient? _accountClient;
  filepb.FileServiceClient? _fileClient;
  chatpb.ChatServiceClient? _chatClient;
  projectpb.ProjectServiceClient? _projectClient;
  searchpb.SearchServiceClient? _searchClient;

  GrpcChannelManager(this._config, this._authInterceptor);

  ClientChannel get channel {
    if (_channel == null) {
      Logs().d('GrpcChannelManager: создание канала ${_config.host}:${_config.port}');
      _channel = ClientChannel(
        _config.host,
        port: _config.port,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
          idleTimeout: Duration(seconds: 30),
        ),
      );
    }
    return _channel!;
  }

  authpb.AuthServiceClient get authClient {
    _authClient ??= authpb.AuthServiceClient(
      channel,
      interceptors: [_authInterceptor],
    );
    return _authClient!;
  }

  accountpb.AccountServiceClient get accountClient {
    _accountClient ??= accountpb.AccountServiceClient(
      channel,
      interceptors: [_authInterceptor],
    );
    return _accountClient!;
  }

  filepb.FileServiceClient get fileClient {
    _fileClient ??= filepb.FileServiceClient(
      channel,
      interceptors: [_authInterceptor],
    );
    return _fileClient!;
  }

  chatpb.ChatServiceClient get chatClient {
    _chatClient ??= chatpb.ChatServiceClient(
      channel,
      interceptors: [_authInterceptor],
    );
    return _chatClient!;
  }

  projectpb.ProjectServiceClient get projectClient {
    _projectClient ??= projectpb.ProjectServiceClient(
      channel,
      interceptors: [_authInterceptor],
    );
    return _projectClient!;
  }

  searchpb.SearchServiceClient get searchClient {
    _searchClient ??= searchpb.SearchServiceClient(
      channel,
      interceptors: [_authInterceptor],
    );
    return _searchClient!;
  }

  Future<void> setServerAddress(String address) async {
    Logs().i('GrpcChannelManager: смена сервера на $address');
    await _config.setServerAddress(address);
    await _closeChannel();
  }

  Future<void> _closeChannel() async {
    final ch = _channel;
    _channel = null;
    _authClient = null;
    _accountClient = null;
    _fileClient = null;
    _chatClient = null;
    _projectClient = null;
    _searchClient = null;
    if (ch != null) {
      Logs().d('GrpcChannelManager: закрытие канала');
      await ch.shutdown();
    }
  }
}
