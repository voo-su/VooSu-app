import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

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

@DriftDatabase(tables: [PendingOutgoingMessages])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(pendingOutgoingMessages);
      }
      if (from < 3) {
        await customStatement('DROP TABLE IF EXISTS cached_messages');
        await customStatement('DROP TABLE IF EXISTS cached_chats');
        await customStatement('DROP TABLE IF EXISTS sync_states');
      }
    },
  );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'voosu_cache.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  Future<void> clearPendingData() async {
    await delete(pendingOutgoingMessages).go();
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
    return (select(pendingOutgoingMessages)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
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
    await (delete(pendingOutgoingMessages)
          ..where((t) => t.localId.equals(localId)))
        .go();
  }
}
