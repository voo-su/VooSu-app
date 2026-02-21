import 'package:voosu/core/failures.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/data_sources/remote/account_remote_datasource.dart';
import 'package:voosu/data/mappers/account_update_mapper.dart';
import 'package:voosu/domain/entities/account_update.dart';
import 'package:voosu/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final IAccountRemoteDataSource dataSource;

  AccountRepositoryImpl(this.dataSource);

  @override
  Future<Stream<AccountUpdate>> getUpdates() async {
    Logs().i('AccountRepositoryImpl - getUpdates');

    return dataSource.getUpdates().asyncExpand((response) async* {
      Logs().i('ChatRepositoryImpl - getUpdates ${response.updates}');

      for (final update in response.updates) {
        final domainUpdate = AccountUpdateMapper.fromGrpc(update);
        if (domainUpdate != null) {
          yield domainUpdate;
        }
      }
    });
  }

  final Map<int, List<int>> _fileCache = {};

  @override
  Future<List<int>> getFile(int fileId) async {
    final cached = _fileCache[fileId];
    if (cached != null) return cached;
    try {
      final bytes = await dataSource.getFile(fileId);
      _fileCache[fileId] = bytes;
      return bytes;
    } catch (e) {
      if (e is Failure) rethrow;
      Logs().e('AccountRepository: ошибка getFile', e);
      throw ApiFailure('Ошибка загрузки файла');
    }
  }

  @override
  void cacheFileBytes(int fileId, List<int> bytes) {
    _fileCache[fileId] = bytes;
  }
}
