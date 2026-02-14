import 'package:voosu/data/data_sources/remote/chat_remote_datasource.dart';
import 'package:voosu/domain/entities/chat.dart';

class GetChatsUseCase {
  final IChatRemoteDataSource _remote;

  GetChatsUseCase(this._remote);

  Future<List<Chat>> call() => _remote.getChats();
}
