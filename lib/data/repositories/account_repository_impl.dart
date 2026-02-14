import 'package:voosu/core/failures.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/data_sources/remote/account_remote_datasource.dart';
import 'package:voosu/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this.dataSource);

  final IAccountRemoteDataSource dataSource;

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
