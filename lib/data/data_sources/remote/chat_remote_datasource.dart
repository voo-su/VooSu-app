import 'dart:async';
import 'dart:math' as math;

import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:voosu/core/auth_guard.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/grpc_channel_manager.dart';
import 'package:voosu/core/grpc_error_handler.dart';
import 'package:voosu/core/log/logs.dart';
import 'package:voosu/data/mappers/chat_mapper.dart';
import 'package:voosu/data/mappers/message_mapper.dart';
import 'package:voosu/data/mappers/user_mapper.dart';
import 'package:voosu/domain/entities/attachment_upload.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/generated/grpc_pb/chat.pbgrpc.dart' as chatpb;
import 'package:voosu/generated/grpc_pb/common.pb.dart' as commonpb;
import 'package:voosu/generated/grpc_pb/file.pbgrpc.dart' as filepb;

abstract class IChatRemoteDataSource {
  Future<Chat> createChat(int userId);

  Future<List<Chat>> getChats();

  Future<Message> sendMessage({
    required int peerUserId,
    required String content,
    List<AttachmentUpload>? attachments,
  });

  Future<int> uploadFile({
    required String filename,
    String mimeType = '',
    required Stream<List<int>> chunkStream,
    int? totalBytes,
    void Function(int sentBytes, int? totalBytes)? onProgress,
  });

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
  filepb.FileServiceClient get _fileClient => _channelManager.fileClient;

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
    Logs().d('ChatRemoteDataSource: getChats');
    try {
      final req = chatpb.GetChatsRequest();
      final resp = await _authGuard.execute(() => _client.getChats(req));

      final users = UserMapper.listFromProto(resp.users);
      final userById = {for (final u in users) u.id: u};
      return ChatMapper.listFromProto(resp.chats, userById);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в getChats', e);
      throwGrpcError(e, 'Ошибка получения чатов');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в getChats', e);
      throw ApiFailure('Ошибка получения чатов');
    }
  }

  @override
  Future<Message> sendMessage({
    required int peerUserId,
    required String content,
    List<AttachmentUpload>? attachments,
  }) async {
    Logs().d('ChatRemoteDataSource: sendMessage peerUserId=$peerUserId');
    try {
      final peer = commonpb.Peer(userId: Int64(peerUserId));
      final attachmentProtos = (attachments ?? []).map((a) => chatpb.AttachmentUpload(
        filename: a.filename,
        fileId: Int64(a.fileId),
      ))
      .toList();
      final req = chatpb.SendMessageRequest(
        peer: peer,
        content: content,
        forwarded: false,
        attachments: attachmentProtos,
      );
      final resp = await _authGuard.execute(() => _client.sendMessage(req));

      return MessageMapper.fromProto(resp);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в sendMessage', e);
      throwGrpcError(e, 'Ошибка отправки сообщения');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в sendMessage', e);
      throw ApiFailure('Ошибка отправки сообщения');
    }
  }

  @override
  Future<int> uploadFile({
    required String filename,
    String mimeType = '',
    required Stream<List<int>> chunkStream,
    int? totalBytes,
    void Function(int sentBytes, int? totalBytes)? onProgress,
  }) async {
    Logs().d('ChatRemoteDataSource: uploadFile filename=$filename');
    try {
      const maxPayload = 2 * 1024 * 1024;
      Stream<filepb.UploadFileRequest> requestStream() async* {
        final meta = filepb.UploadFileMeta(
          filename: filename,
          mimeType: mimeType,
        );
        if (totalBytes != null && totalBytes > 0) {
          meta.totalBytes = Int64(totalBytes);
        }
        yield filepb.UploadFileRequest(meta: meta);
        var partNumber = 1;
        var sent = 0;
        await for (final chunk in chunkStream) {
          if (chunk.isEmpty) {
            continue;
          }
          for (var i = 0; i < chunk.length; i += maxPayload) {
            final end = math.min(i + maxPayload, chunk.length);
            final piece = chunk.sublist(i, end);
            yield filepb.UploadFileRequest(
              chunk: filepb.FileChunk(
                partNumber: partNumber++,
                data: piece,
              ),
            );
            sent += piece.length;
            onProgress?.call(sent, totalBytes);
          }
        }
      }

      final resp = await _authGuard.execute(() => _fileClient.uploadFile(requestStream()));
      return resp.fileId.toInt();
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в uploadFile', e);
      throwGrpcError(e, 'Ошибка загрузки файла');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в uploadFile', e);
      throw ApiFailure('Ошибка загрузки файла');
    }
  }

  @override
  Future<List<Message>> getHistory({
    required int peerUserId,
    required int messageId,
    required int limit,
  }) async {
    Logs().d('ChatRemoteDataSource: getHistory peerUserId=$peerUserId');
    try {
      final peer = commonpb.Peer(userId: Int64(peerUserId));
      final req = chatpb.GetHistoryRequest(
        peer: peer,
        messageId: Int64(messageId),
        limit: Int64(limit),
      );
      final resp = await _authGuard.execute(() => _client.getHistory(req));

      return MessageMapper.listFromProto(resp.messages);
    } on GrpcError catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка gRPC в getHistory', e);
      throwGrpcError(e, 'Ошибка получения сообщений');
    } catch (e) {
      Logs().e('ChatRemoteDataSource: ошибка в getHistory', e);
      throw ApiFailure('Ошибка получения сообщений');
    }
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
