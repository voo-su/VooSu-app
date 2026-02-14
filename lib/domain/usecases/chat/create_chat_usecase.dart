import 'package:voosu/data/data_sources/remote/chat_remote_datasource.dart';
import 'package:voosu/domain/entities/chat.dart';

class CreateChatUseCase {
  final IChatRemoteDataSource _remote;

  CreateChatUseCase(this._remote);

  Future<Chat> call(int userId) => _remote.createChat(userId);
}
