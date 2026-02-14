import 'package:voosu/data/data_sources/remote/chat_remote_datasource.dart';
import 'package:voosu/domain/entities/message.dart';

class GetChatMessagesUseCase {
  final IChatRemoteDataSource _remote;

  GetChatMessagesUseCase(this._remote);

  Future<List<Message>> call({
    required int peerUserId,
    required int messageId,
    required int limit,
  }) =>
      _remote.getHistory(
        peerUserId: peerUserId,
        messageId: messageId,
        limit: limit,
      );
}
