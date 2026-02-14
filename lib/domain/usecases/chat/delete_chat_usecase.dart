import 'package:voosu/data/data_sources/remote/chat_remote_datasource.dart';

class DeleteChatUseCase {
  final IChatRemoteDataSource _remote;

  DeleteChatUseCase(this._remote);

  Future<void> call({required int peerUserId}) => _remote.deleteChat(peerUserId: peerUserId);
}
