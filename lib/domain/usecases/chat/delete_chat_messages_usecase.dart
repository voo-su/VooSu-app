import 'package:voosu/data/data_sources/remote/chat_remote_datasource.dart';

class DeleteChatMessagesUseCase {
  final IChatRemoteDataSource _remote;

  DeleteChatMessagesUseCase(this._remote);

  Future<void> call(List<int> messageIds, {bool forEveryone = true}) => _remote.deleteMessages(messageIds, forEveryone: forEveryone);
}
