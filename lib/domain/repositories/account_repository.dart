import 'package:voosu/domain/entities/account_update.dart';

abstract interface class AccountRepository {
  Future<Stream<AccountUpdate>> getUpdates();

  Future<List<int>> getFile(int fileId);

  void cacheFileBytes(int fileId, List<int> bytes);
}
