import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/entities/chat_attachment.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/entities/poll.dart';
import 'package:voosu/domain/entities/reply_markup.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class SyncStates extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get pts => integer().withDefault(const Constant(0))();

  IntColumn get date => integer().withDefault(const Constant(0))();
}

class CachedMessages extends Table {
  IntColumn get id => integer()();

  BoolColumn get isGroupChat => boolean().withDefault(const Constant(false))();

  IntColumn get peerUserId => integer()();

  IntColumn get peerGroupId => integer().withDefault(const Constant(0))();

  IntColumn get fromPeerUserId => integer()();

  TextColumn get content => text()();

  IntColumn get createdAt => integer()();

  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  IntColumn get replyToMessageId => integer().withDefault(const Constant(0))();

  BoolColumn get forwarded => boolean().withDefault(const Constant(false))();

  IntColumn get forwardedFromMessageId => integer().withDefault(const Constant(0))();

  TextColumn get attachmentsJson => text().nullable()();

  IntColumn get msgType => integer().withDefault(const Constant(1))();

  TextColumn get extraJson => text().nullable()();

  TextColumn get codeLang => text().nullable()();

  TextColumn get codeText => text().nullable()();

  TextColumn get locationLatitude => text().nullable()();

  TextColumn get locationLongitude => text().nullable()();

  TextColumn get locationDescription => text().nullable()();

  TextColumn get replyMarkupJson => text().nullable()();

  TextColumn get pollJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedChats extends Table {
  IntColumn get id => integer()();

  BoolColumn get isGroup => boolean().withDefault(const Constant(false))();

  IntColumn get peerUserId => integer()();

  IntColumn get peerGroupId => integer().withDefault(const Constant(0))();

  TextColumn get title => text()();

  TextColumn get userUsername => text().withDefault(const Constant(''))();

  TextColumn get userName => text().withDefault(const Constant(''))();

  TextColumn get userSurname => text().withDefault(const Constant(''))();

  IntColumn get updatedAt => integer()();

  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  IntColumn get memberCount => integer().withDefault(const Constant(0))();

  IntColumn get avatarFileId => integer().nullable()();

  TextColumn get lastMessagePreview => text().nullable()();

  BoolColumn get notificationsMuted => boolean().withDefault(const Constant(false))();

  IntColumn get listId => integer().withDefault(const Constant(0))();

  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingOutgoingMessages extends Table {
  TextColumn get localId => text()();

  IntColumn get peerUserId => integer()();

  IntColumn get peerGroupId => integer().withDefault(const Constant(0))();

  TextColumn get content => text()();

  TextColumn get attachmentsJson => text().nullable()();

  IntColumn get replyToId => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {localId};
}

@DriftDatabase(
  tables: [
    SyncStates,
    CachedMessages,
    CachedChats,
    PendingOutgoingMessages,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(pendingOutgoingMessages);
      }
      if (from < 3) {
        await migrator.addColumn(cachedChats, cachedChats.listId);
        await migrator.addColumn(cachedChats, cachedChats.isPinned);
      }
      if (from < 4) {
        await migrator.addColumn(cachedMessages, cachedMessages.msgType);
        await migrator.addColumn(cachedMessages, cachedMessages.extraJson);
        await migrator.addColumn(cachedMessages, cachedMessages.codeLang);
        await migrator.addColumn(cachedMessages, cachedMessages.codeText);
        await migrator.addColumn(cachedMessages, cachedMessages.locationLatitude);
        await migrator.addColumn(cachedMessages, cachedMessages.locationLongitude);
        await migrator.addColumn(cachedMessages, cachedMessages.locationDescription);
      }
      if (from < 5) {
        await migrator.addColumn(cachedMessages, cachedMessages.replyMarkupJson);
        await migrator.addColumn(cachedMessages, cachedMessages.pollJson);
      }
    },
  );

  static const _syncStateRowId = 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'voosu_cache.sqlite'));

      return NativeDatabase.createInBackground(file);
    });
  }

  Future<SyncState?> getSyncStateRow() async {
    return await (select(syncStates)..where((t) => t.id.equals(_syncStateRowId))).getSingleOrNull();
  }

  Future<void> setSyncState(int pts, int date) async {
    await into(syncStates).insert(
      SyncStatesCompanion.insert(
        id: Value(_syncStateRowId),
        pts: Value(pts),
        date: Value(date),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> resetSyncState() async {
    await (update(syncStates)..where((t) => t.id.equals(_syncStateRowId))).write(const SyncStatesCompanion(pts: Value(0), date: Value(0)));
  }

  Future<void> initSyncStateIfNeeded() async {
    final existing = await getSyncStateRow();
    if (existing == null) {
      await into(syncStates).insert(
        SyncStatesCompanion.insert(
          id: Value(_syncStateRowId),
          pts: const Value(0),
          date: const Value(0),
        ),
      );
    }
  }

  Future<void> cacheMessage(Message msg) async {
    final int messageId = msg.id;
    final bool isGroupChat = msg.isGroupChat;
    final int peerUserId = msg.peerUserId;
    final int peerGroupId = msg.peerGroupId;
    final int fromPeerUserId = msg.fromPeerUserId;
    final String content = msg.content;
    final int createdAtSec = msg.createdAt.millisecondsSinceEpoch ~/ 1000;
    final bool isRead = msg.isRead;
    final int replyToMessageId = msg.replyToMessageId;
    final bool forwarded = msg.forwarded;
    final int forwardedFromMessageId = msg.forwardedFromMessageId;

    final String? attachmentsJson = msg.attachments.isEmpty
      ? null
      : jsonEncode(
          msg.attachments
              .map(
                (a) => <String, Object?>{
                  'fileId': a.fileId,
                  'filename': a.filename,
                  'mimeType': a.mimeType,
                  'size': a.size,
                  'type': a.type,
                  'externalUrl': a.externalUrl,
                },
              )
              .toList(),
        );
    final String? replyMarkupJson = _cachedReplyMarkupJson(msg.replyMarkup);
    final String? pollJsonEnc = _cachedPollJson(msg.poll);

    await into(cachedMessages).insert(
      CachedMessagesCompanion.insert(
        id: Value(messageId),
        isGroupChat: Value(isGroupChat),
        peerUserId: peerUserId,
        peerGroupId: Value(peerGroupId),
        fromPeerUserId: fromPeerUserId,
        content: content,
        createdAt: createdAtSec,
        isRead: Value(isRead),
        replyToMessageId: Value(replyToMessageId),
        forwarded: Value(forwarded),
        forwardedFromMessageId: Value(forwardedFromMessageId),
        attachmentsJson: attachmentsJson == null
          ? const Value.absent()
          : Value(attachmentsJson),
        msgType: Value(msg.msgType),
        extraJson: msg.extraJson == null || msg.extraJson!.isEmpty
          ? const Value.absent()
          : Value(msg.extraJson),
        codeLang: msg.codeLang == null || msg.codeLang!.isEmpty
          ? const Value.absent()
          : Value(msg.codeLang),
        codeText: msg.codeText == null || msg.codeText!.isEmpty
          ? const Value.absent()
          : Value(msg.codeText),
        locationLatitude:
            msg.locationLatitude == null || msg.locationLatitude!.isEmpty
            ? const Value.absent()
            : Value(msg.locationLatitude),
        locationLongitude:
            msg.locationLongitude == null || msg.locationLongitude!.isEmpty
            ? const Value.absent()
            : Value(msg.locationLongitude),
        locationDescription:
            msg.locationDescription == null ||
                msg.locationDescription!.isEmpty
            ? const Value.absent()
            : Value(msg.locationDescription),
        replyMarkupJson: replyMarkupJson == null
          ? const Value.absent()
          : Value(replyMarkupJson),
        pollJson: pollJsonEnc == null
          ? const Value.absent()
          : Value(pollJsonEnc),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> clearCache() async {
    await delete(cachedMessages).go();
    await delete(cachedChats).go();
    await delete(pendingOutgoingMessages).go();
    await (update(syncStates)..where((t) => t.id.equals(_syncStateRowId))).write(const SyncStatesCompanion(pts: Value(0), date: Value(0)));
  }

  Future<void> insertPendingMessage({
    required String localId,
    required int peerUserId,
    required int peerGroupId,
    required String content,
    String? attachmentsJson,
    int replyToId = 0,
  }) async {
    await into(pendingOutgoingMessages).insert(
      PendingOutgoingMessagesCompanion.insert(
        localId: localId,
        peerUserId: peerUserId,
        peerGroupId: Value(peerGroupId),
        content: content,
        attachmentsJson: Value(attachmentsJson),
        replyToId: Value(replyToId),
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<List<PendingOutgoingMessage>> getPendingOutgoingMessages() async {
    return await (select(pendingOutgoingMessages)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
  }

  Future<List<PendingOutgoingMessage>> getPendingForChat(int chatId) async {
    final isGroup = chatId < 0;
    final peerUserId = isGroup ? 0 : chatId;
    final peerGroupId = isGroup ? -chatId : 0;
    final rows = await (customSelect(
      'SELECT * FROM pending_outgoing_messages WHERE peer_user_id = ? AND peer_group_id = ? ORDER BY created_at ASC',
      variables: [
        Variable.withInt(peerUserId),
        Variable.withInt(peerGroupId),
      ],
      readsFrom: {pendingOutgoingMessages},
    ).map((row) => PendingOutgoingMessage(
      localId: row.read('local_id') as String,
      peerUserId: row.read('peer_user_id') as int,
      peerGroupId: row.read('peer_group_id') as int,
      content: row.read('content') as String,
      attachmentsJson: row.read('attachments_json') as String?,
      replyToId: row.read('reply_to_id') as int,
      createdAt: row.read('created_at') as int,
    )).get());

    return rows;
  }

  Future<void> deletePendingMessage(String localId) async {
    await (delete(pendingOutgoingMessages)..where((t) => t.localId.equals(localId))).go();
  }

  Future<List<Chat>> getCachedChats() async {
    final rows = await (select(cachedChats)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();

    return rows.map(_cachedChatToChat).toList();
  }

  static Chat _cachedChatToChat(CachedChat row) {
    return Chat(
      id: row.id,
      isGroup: row.isGroup,
      peerUserId: row.peerUserId,
      peerGroupId: row.peerGroupId,
      title: row.title,
      userUsername: row.userUsername,
      userName: row.userName,
      userSurname: row.userSurname,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt * 1000),
      unreadCount: row.unreadCount,
      memberCount: row.memberCount,
      avatarFileId: row.avatarFileId,
      lastMessagePreview: row.lastMessagePreview,
      notificationsMuted: row.notificationsMuted,
      listId: row.listId,
      isPinned: row.isPinned,
    );
  }

  Future<void> deleteCachedChat(int chatId) async {
    await (delete(cachedChats)..where((t) => t.id.equals(chatId))).go();
    await clearCachedMessagesForChat(chatId);
  }

  Future<void> deleteCachedMessages(List<int> messageIds) async {
    if (messageIds.isEmpty) {
      return;
    }

    await (delete(cachedMessages)..where((t) => t.id.isIn(messageIds))).go();
  }

  Future<void> clearCachedMessagesForChat(int chatId) async {
    final isGroup = chatId < 0;
    final peerUserId = isGroup ? 0 : chatId;
    final peerGroupId = isGroup ? -chatId : 0;
    await (delete(cachedMessages)..where((t) => t.isGroupChat.equals(isGroup) & t.peerUserId.equals(peerUserId) & t.peerGroupId.equals(peerGroupId))).go();
  }

  Future<void> cacheChats(List<Chat> chats) async {
    for (final chat in chats) {
      await into(cachedChats).insert(
        CachedChatsCompanion.insert(
          id: Value(chat.id),
          isGroup: Value(chat.isGroup),
          peerUserId: chat.peerUserId,
          peerGroupId: Value(chat.peerGroupId),
          title: chat.title,
          userUsername: Value(chat.userUsername),
          userName: Value(chat.userName),
          userSurname: Value(chat.userSurname),
          updatedAt: chat.createdAt.millisecondsSinceEpoch ~/ 1000,
          unreadCount: Value(chat.unreadCount),
          memberCount: Value(chat.memberCount),
          avatarFileId: Value(chat.avatarFileId),
          lastMessagePreview: Value(chat.lastMessagePreview),
          notificationsMuted: Value(chat.notificationsMuted),
          listId: Value(chat.listId),
          isPinned: Value(chat.isPinned),
        ),
        mode: InsertMode.insertOrReplace,
      );
    }
  }

  Future<List<Message>> getCachedMessagesForChat(
    int chatId,
    int limit, {
    int? beforeMessageId,
  }) async {
    final isGroup = chatId < 0;
    final peerUserId = isGroup ? 0 : chatId;
    final peerGroupId = isGroup ? -chatId : 0;
    final beforeId = beforeMessageId ?? 0;

    final selectable = customSelect('SELECT * FROM cached_messages WHERE is_group_chat = ? AND peer_user_id = ? AND peer_group_id = ? AND (? = 0 OR id < ?) ORDER BY created_at DESC LIMIT ?',
      variables: [
        Variable.withBool(isGroup),
        Variable.withInt(peerUserId),
        Variable.withInt(peerGroupId),
        Variable.withInt(beforeId),
        Variable.withInt(beforeId),
        Variable.withInt(limit),
      ],
      readsFrom: {cachedMessages},
    );

    final rows = await selectable
        .map(
          (row) => CachedMessage(
            id: row.read('id') as int,
            isGroupChat: (row.read('is_group_chat') as int) != 0,
            peerUserId: row.read('peer_user_id') as int,
            peerGroupId: row.read('peer_group_id') as int,
            fromPeerUserId: row.read('from_peer_user_id') as int,
            content: row.read('content') as String,
            createdAt: row.read('created_at') as int,
            isRead: (row.read('is_read') as int) != 0,
            replyToMessageId: row.read('reply_to_message_id') as int,
            forwarded: (row.read('forwarded') as int) != 0,
            forwardedFromMessageId:
                row.read('forwarded_from_message_id') as int,
            attachmentsJson: row.read('attachments_json') as String?,
            msgType: row.read<int?>('msg_type') ?? 1,
            extraJson: row.read<String?>('extra_json'),
            codeLang: row.read<String?>('code_lang'),
            codeText: row.read<String?>('code_text'),
            locationLatitude: row.read<String?>('location_latitude'),
            locationLongitude: row.read<String?>('location_longitude'),
            locationDescription: row.read<String?>('location_description'),
            replyMarkupJson: row.read<String?>('reply_markup_json'),
            pollJson: row.read<String?>('poll_json'),
          ),
        )
        .get();
    return rows.map(_cachedMessageToMessage).toList();
  }

  static Message _cachedMessageToMessage(CachedMessage row) {
    List<ChatAttachment> attachments = const [];
    if (row.attachmentsJson != null && row.attachmentsJson!.isNotEmpty) {
      try {
        final list = jsonDecode(row.attachmentsJson!) as List<dynamic>;
        attachments = list.map((e) {
          final m = e as Map<String, dynamic>;
          return ChatAttachment(
            fileId: (m['fileId'] as num?)?.toInt() ?? 0,
            filename: m['filename'] as String? ?? '',
            mimeType: m['mimeType'] as String? ?? '',
            size: (m['size'] as num?)?.toInt() ?? 0,
            type: (m['type'] as num?)?.toInt() ?? 0,
            externalUrl: m['externalUrl'] as String?,
          );
        }).toList();
      } catch (_) {}
    }

    return Message(
      id: row.id,
      isGroupChat: row.isGroupChat,
      peerUserId: row.peerUserId,
      peerGroupId: row.peerGroupId,
      fromPeerUserId: row.fromPeerUserId,
      msgType: row.msgType,
      extraJson: row.extraJson,
      codeLang: row.codeLang,
      codeText: row.codeText,
      locationLatitude: row.locationLatitude,
      locationLongitude: row.locationLongitude,
      locationDescription: row.locationDescription,
      content: row.content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt * 1000),
      isRead: row.isRead,
      replyToMessageId: row.replyToMessageId,
      forwarded: row.forwarded,
      forwardedFromMessageId: row.forwardedFromMessageId,
      attachments: attachments,
      replyMarkup: _parseCachedReplyMarkup(row.replyMarkupJson),
      poll: _parseCachedPoll(row.pollJson),
    );
  }

  Future<bool> hasOlderCachedMessages(
    int chatId,
    int oldestMessageId,
  ) async {
    final isGroup = chatId < 0;
    final peerUserId = isGroup ? 0 : chatId;
    final peerGroupId = isGroup ? -chatId : 0;
    final count = await (selectOnly(cachedMessages)
      ..addColumns([cachedMessages.id.count()])
      ..where(cachedMessages.isGroupChat.equals(isGroup) & cachedMessages.peerUserId.equals(peerUserId) & cachedMessages.peerGroupId.equals(peerGroupId) & cachedMessages.id.isSmallerThanValue(oldestMessageId)))
      .getSingle();

    return (count.read(cachedMessages.id.count()) ?? 0) > 0;
  }
}

String? _cachedReplyMarkupJson(ReplyMarkup? r) {
  if (r == null || r.isEmpty) {
    return null;
  }
  final rows = r.inlineKeyboard
      .map(
        (row) => row.buttons
            .map(
              (b) => <String, Object?>{
                'text': b.text,
                'callback_data': b.callbackData,
              },
            )
            .toList(),
      )
      .toList();
  return jsonEncode(<String, Object?>{'inline_keyboard': rows});
}

ReplyMarkup? _parseCachedReplyMarkup(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  try {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    final kb = m['inline_keyboard'];
    if (kb is! List<dynamic>) {
      return null;
    }
    final rows = <InlineKeyboardRow>[];
    for (final row in kb) {
      if (row is! List<dynamic>) {
        continue;
      }
      final buttons = <InlineKeyboardButton>[];
      for (final b in row) {
        if (b is! Map) {
          continue;
        }
        final bm = Map<String, dynamic>.from(b);
        buttons.add(
          InlineKeyboardButton(
            text: bm['text'] as String? ?? '',
            callbackData: bm['callback_data'] as String? ?? '',
          ),
        );
      }
      if (buttons.isNotEmpty) {
        rows.add(InlineKeyboardRow(buttons: buttons));
      }
    }
    if (rows.isEmpty) {
      return null;
    }
    return ReplyMarkup(inlineKeyboard: rows);
  } catch (_) {
    return null;
  }
}

String? _cachedPollJson(Poll? p) {
  if (p == null) {
    return null;
  }
  return jsonEncode(<String, Object?>{
    'id': p.id,
    'question': p.question,
    'anonymous': p.anonymous,
    'options': p.options
        .map(
          (o) => <String, Object?>{
            'optionId': o.optionId,
            'text': o.text,
            'position': o.position,
            'voteCount': o.voteCount,
            'voterUserIds': o.voterUserIds,
          },
        )
        .toList(),
  });
}

Poll? _parseCachedPoll(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  try {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    final opts = m['options'];
    if (opts is! List<dynamic>) {
      return null;
    }
    final options = <PollOptionResult>[];
    for (final e in opts) {
      if (e is! Map) {
        continue;
      }
      final em = Map<String, dynamic>.from(e);
      final voters = em['voterUserIds'];
      final uidList = <int>[];
      if (voters is List<dynamic>) {
        for (final v in voters) {
          if (v is num) {
            uidList.add(v.toInt());
          }
        }
      }
      options.add(
        PollOptionResult(
          optionId: (em['optionId'] as num?)?.toInt() ?? 0,
          text: em['text'] as String? ?? '',
          position: (em['position'] as num?)?.toInt() ?? 0,
          voteCount: (em['voteCount'] as num?)?.toInt() ?? 0,
          voterUserIds: uidList,
        ),
      );
    }
    return Poll(
      id: (m['id'] as num?)?.toInt() ?? 0,
      question: m['question'] as String? ?? '',
      anonymous: m['anonymous'] == true,
      options: options,
    );
  } catch (_) {
    return null;
  }
}
