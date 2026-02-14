import 'package:grpc/grpc.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/grpc_error_handler.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/mappers/user_mapper.dart';
import 'package:voosu/domain/entities/user.dart';
import 'package:voosu/generated/grpc_pb/search.pbgrpc.dart' as searchpb;

abstract class ISearchRemoteDataSource {
  Future<(List<User>, int)> searchUsers({
    required String query,
    required int page,
    required int pageSize,
  });
}

class SearchRemoteDataSource implements ISearchRemoteDataSource {
  SearchRemoteDataSource(ClientChannel channel) : _channel = channel;

  final ClientChannel _channel;
  searchpb.SearchServiceClient? _clientHolder;

  searchpb.SearchServiceClient get _client =>
      _clientHolder ??= searchpb.SearchServiceClient(_channel);

  @override
  Future<(List<User>, int)> searchUsers({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    Logs().d('SearchRemoteDataSource: поиск пользователей query="$query"');
    try {
      final req = searchpb.SearchUsersRequest(
        query: query,
        page: page,
        pageSize: pageSize,
      );
      final resp = await _client.users(req);
      final users = UserMapper.listFromProto(resp.users);

      return (users, resp.total);
    } on GrpcError catch (e) {
      Logs().e('SearchRemoteDataSource: ошибка gRPC', e);
      throwGrpcError(e, 'Ошибка поиска пользователей');
    } catch (e) {
      Logs().e('SearchRemoteDataSource: неожиданная ошибка', e);
      throw ApiFailure('Ошибка поиска пользователей');
    }
  }
}
