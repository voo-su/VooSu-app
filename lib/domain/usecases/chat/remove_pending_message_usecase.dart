import 'package:voosu/data/db/app_database.dart';

class RemovePendingMessageUseCase {
  final AppDatabase _db;

  RemovePendingMessageUseCase(this._db);

  Future<void> call(String localId) => _db.deletePendingMessage(localId);
}
