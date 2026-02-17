import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:voosu/core/auth_guard.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/grpc_channel_manager.dart';
import 'package:voosu/core/grpc_error_handler.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/mappers/chat_mapper.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/generated/grpc_pb/chat.pbgrpc.dart' as chatpb;
import 'package:voosu/generated/grpc_pb/common.pb.dart' as commonpb;

abstract class IChatRemoteDataSource {
  Future<Chat> createChat(int userId);

  Future<List<Chat>> getChats();

  Future<List<Message>> getHistory({
    required int peerUserId,
    required int messageId,
    required int limit,
  });

  Future<void> deleteMessages(List<int> messageIds, {bool forEveryone = true});

  Future<void> clearHistory({required int peerUserId});

  Future<void> deleteChat({required int peerUserId});
}

class ChatRemoteDataSource implements IChatRemoteDataSource {
  final GrpcChannelManager _channelManager;
  final AuthGuard _authGuard;

  ChatRemoteDataSource(this._channelManager, this._authGuard);

  chatpb.ChatServiceClient get _client => _channelManager.chatClient;

  @override
  Future<Chat> createChat(int userId) async {
    Logs().d('ChatRemoteDataSource: createChat userId=$userId');
    try {
      final req = chatpb.CreateChatRequest(userId: Int64(userId));
      final resp = await _authGuard.execute(() => _client.createChat(req));

      return ChatMapper.fromProto(resp);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в createChat', e);
      throwGrpcError(e, 'Ошибка открытия чата');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в createChat', e);
      throw ApiFailure('Ошибка открытия чата');
    }
  }

  @override
  Future<List<Chat>> getChats() async {
    Logs().d('ChatRemoteDataSource: getChats — без gRPC');
    return [];
  }

  @override
  Future<List<Message>> getHistory({
    required int peerUserId,
    required int messageId,
    required int limit,
  }) async {
    Logs().d(
      'ChatRemoteDataSource: getHistory — без gRPC peerUserId=$peerUserId',
    );
    return [];
  }

  @override
  Future<void> deleteMessages(
    List<int> messageIds, {
    bool forEveryone = true,
  }) async {
    if (messageIds.isEmpty) return;
    Logs().d('ChatRemoteDataSource: deleteMessages count=${messageIds.length} forEveryone=$forEveryone');
    try {
      final req = chatpb.DeleteMessagesRequest(
        messageIds: messageIds.map((id) => Int64(id)).toList(),
        revoke: forEveryone,
      );
      await _authGuard.execute(() => _client.deleteMessages(req));
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в deleteMessages', e);
      throwGrpcError(e, 'Ошибка удаления сообщений');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в deleteMessages', e);
      throw ApiFailure('Ошибка удаления сообщений');
    }
  }

  @override
  Future<void> clearHistory({required int peerUserId}) async {
    Logs().d('ChatRemoteDataSource: clearHistory peerUserId=$peerUserId');
    try {
      final peer = commonpb.Peer(userId: Int64(peerUserId));
      final req = chatpb.ClearHistoryRequest(peer: peer);
      await _authGuard.execute(() => _client.clearHistory(req));
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в clearHistory', e);
      throwGrpcError(e, 'Ошибка очистки истории');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в clearHistory', e);
      throw ApiFailure('Ошибка очистки истории');
    }
  }

  @override
  Future<void> deleteChat({required int peerUserId}) async {
    Logs().d('ChatRemoteDataSource: deleteChat peerUserId=$peerUserId');
    try {
      final peer = commonpb.Peer(userId: Int64(peerUserId));
      final req = chatpb.DeleteChatRequest(peer: peer);
      await _authGuard.execute(() => _client.deleteChat(req));
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в deleteChat', e);
      throwGrpcError(e, 'Ошибка удаления чата');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в deleteChat', e);
      throw ApiFailure('Ошибка удаления чата');
    }
  }
}
