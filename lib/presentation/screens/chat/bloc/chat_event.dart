import 'package:equatable/equatable.dart';
import 'package:voosu/domain/entities/attachment_upload.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/entities/pending_queue_item.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatStarted extends ChatEvent {
  const ChatStarted();
}

class ChatLoadChats extends ChatEvent {
  final int page;
  final int pageSize;
  final bool silent;

  const ChatLoadChats({this.page = 1, this.pageSize = 50, this.silent = false});

  @override
  List<Object?> get props => [page, pageSize, silent];
}

class ChatOpenWithUser extends ChatEvent {
  final int userId;

  const ChatOpenWithUser(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ChatSelectChat extends ChatEvent {
  final Chat chat;

  const ChatSelectChat(this.chat);

  @override
  List<Object?> get props => [chat];
}

class ChatMessagesForChatLoaded extends ChatEvent {
  final Chat chat;
  final List<Message> messages;
  final List<Chat> updatedChats;
  final List<PendingQueueItem> pendingQueue;

  const ChatMessagesForChatLoaded({
    required this.chat,
    required this.messages,
    required this.updatedChats,
    this.pendingQueue = const [],
  });

  @override
  List<Object?> get props => [chat, messages, updatedChats, pendingQueue];
}

class ChatSendMessage extends ChatEvent {
  final String text;
  final List<AttachmentUpload>? attachments;

  const ChatSendMessage(
    this.text, {
    this.attachments,
  });

  @override
  List<Object?> get props => [text, attachments];
}

class ChatStartSendingMessage extends ChatEvent {
  final String clientId;
  final String text;
  final List<AttachmentUpload>? attachments;
  final List<LargeFileRef>? largeFiles;

  const ChatStartSendingMessage({
    required this.clientId,
    required this.text,
    this.attachments,
    this.largeFiles,
  });

  @override
  List<Object?> get props => [
    clientId,
    text,
    attachments,
    largeFiles,
  ];
}

class LargeFileRef extends Equatable {
  final String path;
  final String filename;
  final int size;

  const LargeFileRef({
    required this.path,
    required this.filename,
    required this.size,
  });

  @override
  List<Object?> get props => [path, filename, size];
}

class ChatUploadProgress extends ChatEvent {
  final String clientId;
  final String filename;
  final int sentBytes;
  final int? totalBytes;

  const ChatUploadProgress(
    this.clientId,
    this.filename,
    this.sentBytes,
    this.totalBytes,
  );

  @override
  List<Object?> get props => [clientId, filename, sentBytes, totalBytes];
}

class ChatUploadFileComplete extends ChatEvent {
  final String clientId;
  final String filename;
  final int fileId;

  const ChatUploadFileComplete(this.clientId, this.filename, this.fileId);

  @override
  List<Object?> get props => [clientId, filename, fileId];
}

class ChatSubmitPendingMessage extends ChatEvent {
  final String clientId;

  const ChatSubmitPendingMessage(this.clientId);

  @override
  List<Object?> get props => [clientId];
}

class ChatCancelPendingMessage extends ChatEvent {
  final String clientId;

  const ChatCancelPendingMessage(this.clientId);

  @override
  List<Object?> get props => [clientId];
}

class ChatClearError extends ChatEvent {
  const ChatClearError();
}

class ChatBackToList extends ChatEvent {
  const ChatBackToList();
}

class ChatDeleteMessage extends ChatEvent {
  final Message message;
  final bool forEveryone;

  const ChatDeleteMessage(this.message, {this.forEveryone = true});

  @override
  List<Object?> get props => [message, forEveryone];
}

class ChatToggleMessageSelection extends ChatEvent {
  final Message message;

  const ChatToggleMessageSelection(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatDeleteSelectedMessages extends ChatEvent {
  final bool forEveryone;

  const ChatDeleteSelectedMessages({this.forEveryone = true});

  @override
  List<Object?> get props => [forEveryone];
}

class ChatClearSelection extends ChatEvent {
  const ChatClearSelection();
}

class ChatSelectAllMyMessages extends ChatEvent {
  const ChatSelectAllMyMessages();
}

class ChatClearHistory extends ChatEvent {
  const ChatClearHistory();
}

class ChatDeleteChat extends ChatEvent {
  final Chat chat;

  const ChatDeleteChat(this.chat);

  @override
  List<Object?> get props => [chat];
}

class ChatLoadMoreMessages extends ChatEvent {
  const ChatLoadMoreMessages();
}

class ChatCancelPendingFromQueue extends ChatEvent {
  final String localId;

  const ChatCancelPendingFromQueue(this.localId);

  @override
  List<Object?> get props => [localId];
}

