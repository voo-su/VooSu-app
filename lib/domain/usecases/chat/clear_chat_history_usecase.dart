import 'package:voosu/data/data_sources/remote/chat_remote_datasource.dart';

class ClearChatHistoryUseCase {
  final IChatRemoteDataSource _remote;

  ClearChatHistoryUseCase(this._remote);

  Future<void> call({required int peerUserId}) => _remote.clearHistory(peerUserId: peerUserId);
}
