// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SyncStatesTable extends SyncStates
    with TableInfo<$SyncStatesTable, SyncState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _ptsMeta = const VerificationMeta('pts');
  @override
  late final GeneratedColumn<int> pts = GeneratedColumn<int>(
    'pts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, pts, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pts')) {
      context.handle(
        _ptsMeta,
        pts.isAcceptableOrUnknown(data['pts']!, _ptsMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncState(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      pts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pts'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $SyncStatesTable createAlias(String alias) {
    return $SyncStatesTable(attachedDatabase, alias);
  }
}

class SyncState extends DataClass implements Insertable<SyncState> {
  final int id;
  final int pts;
  final int date;
  const SyncState({required this.id, required this.pts, required this.date});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pts'] = Variable<int>(pts);
    map['date'] = Variable<int>(date);
    return map;
  }

  SyncStatesCompanion toCompanion(bool nullToAbsent) {
    return SyncStatesCompanion(
      id: Value(id),
      pts: Value(pts),
      date: Value(date),
    );
  }

  factory SyncState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncState(
      id: serializer.fromJson<int>(json['id']),
      pts: serializer.fromJson<int>(json['pts']),
      date: serializer.fromJson<int>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pts': serializer.toJson<int>(pts),
      'date': serializer.toJson<int>(date),
    };
  }

  SyncState copyWith({int? id, int? pts, int? date}) => SyncState(
    id: id ?? this.id,
    pts: pts ?? this.pts,
    date: date ?? this.date,
  );
  SyncState copyWithCompanion(SyncStatesCompanion data) {
    return SyncState(
      id: data.id.present ? data.id.value : this.id,
      pts: data.pts.present ? data.pts.value : this.pts,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncState(')
          ..write('id: $id, ')
          ..write('pts: $pts, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pts, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncState &&
          other.id == this.id &&
          other.pts == this.pts &&
          other.date == this.date);
}

class SyncStatesCompanion extends UpdateCompanion<SyncState> {
  final Value<int> id;
  final Value<int> pts;
  final Value<int> date;
  const SyncStatesCompanion({
    this.id = const Value.absent(),
    this.pts = const Value.absent(),
    this.date = const Value.absent(),
  });
  SyncStatesCompanion.insert({
    this.id = const Value.absent(),
    this.pts = const Value.absent(),
    this.date = const Value.absent(),
  });
  static Insertable<SyncState> custom({
    Expression<int>? id,
    Expression<int>? pts,
    Expression<int>? date,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pts != null) 'pts': pts,
      if (date != null) 'date': date,
    });
  }

  SyncStatesCompanion copyWith({
    Value<int>? id,
    Value<int>? pts,
    Value<int>? date,
  }) {
    return SyncStatesCompanion(
      id: id ?? this.id,
      pts: pts ?? this.pts,
      date: date ?? this.date,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pts.present) {
      map['pts'] = Variable<int>(pts.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatesCompanion(')
          ..write('id: $id, ')
          ..write('pts: $pts, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }
}

class $CachedMessagesTable extends CachedMessages
    with TableInfo<$CachedMessagesTable, CachedMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isGroupChatMeta = const VerificationMeta(
    'isGroupChat',
  );
  @override
  late final GeneratedColumn<bool> isGroupChat = GeneratedColumn<bool>(
    'is_group_chat',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_group_chat" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _peerUserIdMeta = const VerificationMeta(
    'peerUserId',
  );
  @override
  late final GeneratedColumn<int> peerUserId = GeneratedColumn<int>(
    'peer_user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerGroupIdMeta = const VerificationMeta(
    'peerGroupId',
  );
  @override
  late final GeneratedColumn<int> peerGroupId = GeneratedColumn<int>(
    'peer_group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fromPeerUserIdMeta = const VerificationMeta(
    'fromPeerUserId',
  );
  @override
  late final GeneratedColumn<int> fromPeerUserId = GeneratedColumn<int>(
    'from_peer_user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _replyToMessageIdMeta = const VerificationMeta(
    'replyToMessageId',
  );
  @override
  late final GeneratedColumn<int> replyToMessageId = GeneratedColumn<int>(
    'reply_to_message_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _forwardedMeta = const VerificationMeta(
    'forwarded',
  );
  @override
  late final GeneratedColumn<bool> forwarded = GeneratedColumn<bool>(
    'forwarded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("forwarded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _forwardedFromMessageIdMeta =
      const VerificationMeta('forwardedFromMessageId');
  @override
  late final GeneratedColumn<int> forwardedFromMessageId = GeneratedColumn<int>(
    'forwarded_from_message_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _attachmentsJsonMeta = const VerificationMeta(
    'attachmentsJson',
  );
  @override
  late final GeneratedColumn<String> attachmentsJson = GeneratedColumn<String>(
    'attachments_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _msgTypeMeta = const VerificationMeta(
    'msgType',
  );
  @override
  late final GeneratedColumn<int> msgType = GeneratedColumn<int>(
    'msg_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _extraJsonMeta = const VerificationMeta(
    'extraJson',
  );
  @override
  late final GeneratedColumn<String> extraJson = GeneratedColumn<String>(
    'extra_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeLangMeta = const VerificationMeta(
    'codeLang',
  );
  @override
  late final GeneratedColumn<String> codeLang = GeneratedColumn<String>(
    'code_lang',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeTextMeta = const VerificationMeta(
    'codeText',
  );
  @override
  late final GeneratedColumn<String> codeText = GeneratedColumn<String>(
    'code_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationLatitudeMeta = const VerificationMeta(
    'locationLatitude',
  );
  @override
  late final GeneratedColumn<String> locationLatitude = GeneratedColumn<String>(
    'location_latitude',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationLongitudeMeta = const VerificationMeta(
    'locationLongitude',
  );
  @override
  late final GeneratedColumn<String> locationLongitude =
      GeneratedColumn<String>(
        'location_longitude',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _locationDescriptionMeta =
      const VerificationMeta('locationDescription');
  @override
  late final GeneratedColumn<String> locationDescription =
      GeneratedColumn<String>(
        'location_description',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _replyMarkupJsonMeta = const VerificationMeta(
    'replyMarkupJson',
  );
  @override
  late final GeneratedColumn<String> replyMarkupJson = GeneratedColumn<String>(
    'reply_markup_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pollJsonMeta = const VerificationMeta(
    'pollJson',
  );
  @override
  late final GeneratedColumn<String> pollJson = GeneratedColumn<String>(
    'poll_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isGroupChat,
    peerUserId,
    peerGroupId,
    fromPeerUserId,
    content,
    createdAt,
    isRead,
    replyToMessageId,
    forwarded,
    forwardedFromMessageId,
    attachmentsJson,
    msgType,
    extraJson,
    codeLang,
    codeText,
    locationLatitude,
    locationLongitude,
    locationDescription,
    replyMarkupJson,
    pollJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('is_group_chat')) {
      context.handle(
        _isGroupChatMeta,
        isGroupChat.isAcceptableOrUnknown(
          data['is_group_chat']!,
          _isGroupChatMeta,
        ),
      );
    }
    if (data.containsKey('peer_user_id')) {
      context.handle(
        _peerUserIdMeta,
        peerUserId.isAcceptableOrUnknown(
          data['peer_user_id']!,
          _peerUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peerUserIdMeta);
    }
    if (data.containsKey('peer_group_id')) {
      context.handle(
        _peerGroupIdMeta,
        peerGroupId.isAcceptableOrUnknown(
          data['peer_group_id']!,
          _peerGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('from_peer_user_id')) {
      context.handle(
        _fromPeerUserIdMeta,
        fromPeerUserId.isAcceptableOrUnknown(
          data['from_peer_user_id']!,
          _fromPeerUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromPeerUserIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('reply_to_message_id')) {
      context.handle(
        _replyToMessageIdMeta,
        replyToMessageId.isAcceptableOrUnknown(
          data['reply_to_message_id']!,
          _replyToMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('forwarded')) {
      context.handle(
        _forwardedMeta,
        forwarded.isAcceptableOrUnknown(data['forwarded']!, _forwardedMeta),
      );
    }
    if (data.containsKey('forwarded_from_message_id')) {
      context.handle(
        _forwardedFromMessageIdMeta,
        forwardedFromMessageId.isAcceptableOrUnknown(
          data['forwarded_from_message_id']!,
          _forwardedFromMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('attachments_json')) {
      context.handle(
        _attachmentsJsonMeta,
        attachmentsJson.isAcceptableOrUnknown(
          data['attachments_json']!,
          _attachmentsJsonMeta,
        ),
      );
    }
    if (data.containsKey('msg_type')) {
      context.handle(
        _msgTypeMeta,
        msgType.isAcceptableOrUnknown(data['msg_type']!, _msgTypeMeta),
      );
    }
    if (data.containsKey('extra_json')) {
      context.handle(
        _extraJsonMeta,
        extraJson.isAcceptableOrUnknown(data['extra_json']!, _extraJsonMeta),
      );
    }
    if (data.containsKey('code_lang')) {
      context.handle(
        _codeLangMeta,
        codeLang.isAcceptableOrUnknown(data['code_lang']!, _codeLangMeta),
      );
    }
    if (data.containsKey('code_text')) {
      context.handle(
        _codeTextMeta,
        codeText.isAcceptableOrUnknown(data['code_text']!, _codeTextMeta),
      );
    }
    if (data.containsKey('location_latitude')) {
      context.handle(
        _locationLatitudeMeta,
        locationLatitude.isAcceptableOrUnknown(
          data['location_latitude']!,
          _locationLatitudeMeta,
        ),
      );
    }
    if (data.containsKey('location_longitude')) {
      context.handle(
        _locationLongitudeMeta,
        locationLongitude.isAcceptableOrUnknown(
          data['location_longitude']!,
          _locationLongitudeMeta,
        ),
      );
    }
    if (data.containsKey('location_description')) {
      context.handle(
        _locationDescriptionMeta,
        locationDescription.isAcceptableOrUnknown(
          data['location_description']!,
          _locationDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('reply_markup_json')) {
      context.handle(
        _replyMarkupJsonMeta,
        replyMarkupJson.isAcceptableOrUnknown(
          data['reply_markup_json']!,
          _replyMarkupJsonMeta,
        ),
      );
    }
    if (data.containsKey('poll_json')) {
      context.handle(
        _pollJsonMeta,
        pollJson.isAcceptableOrUnknown(data['poll_json']!, _pollJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      isGroupChat: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_group_chat'],
      )!,
      peerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}peer_user_id'],
      )!,
      peerGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}peer_group_id'],
      )!,
      fromPeerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_peer_user_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      replyToMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reply_to_message_id'],
      )!,
      forwarded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}forwarded'],
      )!,
      forwardedFromMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}forwarded_from_message_id'],
      )!,
      attachmentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachments_json'],
      ),
      msgType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}msg_type'],
      )!,
      extraJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra_json'],
      ),
      codeLang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code_lang'],
      ),
      codeText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code_text'],
      ),
      locationLatitude: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_latitude'],
      ),
      locationLongitude: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_longitude'],
      ),
      locationDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_description'],
      ),
      replyMarkupJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_markup_json'],
      ),
      pollJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poll_json'],
      ),
    );
  }

  @override
  $CachedMessagesTable createAlias(String alias) {
    return $CachedMessagesTable(attachedDatabase, alias);
  }
}

class CachedMessage extends DataClass implements Insertable<CachedMessage> {
  final int id;
  final bool isGroupChat;
  final int peerUserId;
  final int peerGroupId;
  final int fromPeerUserId;
  final String content;
  final int createdAt;
  final bool isRead;
  final int replyToMessageId;
  final bool forwarded;
  final int forwardedFromMessageId;
  final String? attachmentsJson;
  final int msgType;
  final String? extraJson;
  final String? codeLang;
  final String? codeText;
  final String? locationLatitude;
  final String? locationLongitude;
  final String? locationDescription;
  final String? replyMarkupJson;
  final String? pollJson;
  const CachedMessage({
    required this.id,
    required this.isGroupChat,
    required this.peerUserId,
    required this.peerGroupId,
    required this.fromPeerUserId,
    required this.content,
    required this.createdAt,
    required this.isRead,
    required this.replyToMessageId,
    required this.forwarded,
    required this.forwardedFromMessageId,
    this.attachmentsJson,
    required this.msgType,
    this.extraJson,
    this.codeLang,
    this.codeText,
    this.locationLatitude,
    this.locationLongitude,
    this.locationDescription,
    this.replyMarkupJson,
    this.pollJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['is_group_chat'] = Variable<bool>(isGroupChat);
    map['peer_user_id'] = Variable<int>(peerUserId);
    map['peer_group_id'] = Variable<int>(peerGroupId);
    map['from_peer_user_id'] = Variable<int>(fromPeerUserId);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<int>(createdAt);
    map['is_read'] = Variable<bool>(isRead);
    map['reply_to_message_id'] = Variable<int>(replyToMessageId);
    map['forwarded'] = Variable<bool>(forwarded);
    map['forwarded_from_message_id'] = Variable<int>(forwardedFromMessageId);
    if (!nullToAbsent || attachmentsJson != null) {
      map['attachments_json'] = Variable<String>(attachmentsJson);
    }
    map['msg_type'] = Variable<int>(msgType);
    if (!nullToAbsent || extraJson != null) {
      map['extra_json'] = Variable<String>(extraJson);
    }
    if (!nullToAbsent || codeLang != null) {
      map['code_lang'] = Variable<String>(codeLang);
    }
    if (!nullToAbsent || codeText != null) {
      map['code_text'] = Variable<String>(codeText);
    }
    if (!nullToAbsent || locationLatitude != null) {
      map['location_latitude'] = Variable<String>(locationLatitude);
    }
    if (!nullToAbsent || locationLongitude != null) {
      map['location_longitude'] = Variable<String>(locationLongitude);
    }
    if (!nullToAbsent || locationDescription != null) {
      map['location_description'] = Variable<String>(locationDescription);
    }
    if (!nullToAbsent || replyMarkupJson != null) {
      map['reply_markup_json'] = Variable<String>(replyMarkupJson);
    }
    if (!nullToAbsent || pollJson != null) {
      map['poll_json'] = Variable<String>(pollJson);
    }
    return map;
  }

  CachedMessagesCompanion toCompanion(bool nullToAbsent) {
    return CachedMessagesCompanion(
      id: Value(id),
      isGroupChat: Value(isGroupChat),
      peerUserId: Value(peerUserId),
      peerGroupId: Value(peerGroupId),
      fromPeerUserId: Value(fromPeerUserId),
      content: Value(content),
      createdAt: Value(createdAt),
      isRead: Value(isRead),
      replyToMessageId: Value(replyToMessageId),
      forwarded: Value(forwarded),
      forwardedFromMessageId: Value(forwardedFromMessageId),
      attachmentsJson: attachmentsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentsJson),
      msgType: Value(msgType),
      extraJson: extraJson == null && nullToAbsent
          ? const Value.absent()
          : Value(extraJson),
      codeLang: codeLang == null && nullToAbsent
          ? const Value.absent()
          : Value(codeLang),
      codeText: codeText == null && nullToAbsent
          ? const Value.absent()
          : Value(codeText),
      locationLatitude: locationLatitude == null && nullToAbsent
          ? const Value.absent()
          : Value(locationLatitude),
      locationLongitude: locationLongitude == null && nullToAbsent
          ? const Value.absent()
          : Value(locationLongitude),
      locationDescription: locationDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(locationDescription),
      replyMarkupJson: replyMarkupJson == null && nullToAbsent
          ? const Value.absent()
          : Value(replyMarkupJson),
      pollJson: pollJson == null && nullToAbsent
          ? const Value.absent()
          : Value(pollJson),
    );
  }

  factory CachedMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMessage(
      id: serializer.fromJson<int>(json['id']),
      isGroupChat: serializer.fromJson<bool>(json['isGroupChat']),
      peerUserId: serializer.fromJson<int>(json['peerUserId']),
      peerGroupId: serializer.fromJson<int>(json['peerGroupId']),
      fromPeerUserId: serializer.fromJson<int>(json['fromPeerUserId']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      replyToMessageId: serializer.fromJson<int>(json['replyToMessageId']),
      forwarded: serializer.fromJson<bool>(json['forwarded']),
      forwardedFromMessageId: serializer.fromJson<int>(
        json['forwardedFromMessageId'],
      ),
      attachmentsJson: serializer.fromJson<String?>(json['attachmentsJson']),
      msgType: serializer.fromJson<int>(json['msgType']),
      extraJson: serializer.fromJson<String?>(json['extraJson']),
      codeLang: serializer.fromJson<String?>(json['codeLang']),
      codeText: serializer.fromJson<String?>(json['codeText']),
      locationLatitude: serializer.fromJson<String?>(json['locationLatitude']),
      locationLongitude: serializer.fromJson<String?>(
        json['locationLongitude'],
      ),
      locationDescription: serializer.fromJson<String?>(
        json['locationDescription'],
      ),
      replyMarkupJson: serializer.fromJson<String?>(json['replyMarkupJson']),
      pollJson: serializer.fromJson<String?>(json['pollJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'isGroupChat': serializer.toJson<bool>(isGroupChat),
      'peerUserId': serializer.toJson<int>(peerUserId),
      'peerGroupId': serializer.toJson<int>(peerGroupId),
      'fromPeerUserId': serializer.toJson<int>(fromPeerUserId),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<int>(createdAt),
      'isRead': serializer.toJson<bool>(isRead),
      'replyToMessageId': serializer.toJson<int>(replyToMessageId),
      'forwarded': serializer.toJson<bool>(forwarded),
      'forwardedFromMessageId': serializer.toJson<int>(forwardedFromMessageId),
      'attachmentsJson': serializer.toJson<String?>(attachmentsJson),
      'msgType': serializer.toJson<int>(msgType),
      'extraJson': serializer.toJson<String?>(extraJson),
      'codeLang': serializer.toJson<String?>(codeLang),
      'codeText': serializer.toJson<String?>(codeText),
      'locationLatitude': serializer.toJson<String?>(locationLatitude),
      'locationLongitude': serializer.toJson<String?>(locationLongitude),
      'locationDescription': serializer.toJson<String?>(locationDescription),
      'replyMarkupJson': serializer.toJson<String?>(replyMarkupJson),
      'pollJson': serializer.toJson<String?>(pollJson),
    };
  }

  CachedMessage copyWith({
    int? id,
    bool? isGroupChat,
    int? peerUserId,
    int? peerGroupId,
    int? fromPeerUserId,
    String? content,
    int? createdAt,
    bool? isRead,
    int? replyToMessageId,
    bool? forwarded,
    int? forwardedFromMessageId,
    Value<String?> attachmentsJson = const Value.absent(),
    int? msgType,
    Value<String?> extraJson = const Value.absent(),
    Value<String?> codeLang = const Value.absent(),
    Value<String?> codeText = const Value.absent(),
    Value<String?> locationLatitude = const Value.absent(),
    Value<String?> locationLongitude = const Value.absent(),
    Value<String?> locationDescription = const Value.absent(),
    Value<String?> replyMarkupJson = const Value.absent(),
    Value<String?> pollJson = const Value.absent(),
  }) => CachedMessage(
    id: id ?? this.id,
    isGroupChat: isGroupChat ?? this.isGroupChat,
    peerUserId: peerUserId ?? this.peerUserId,
    peerGroupId: peerGroupId ?? this.peerGroupId,
    fromPeerUserId: fromPeerUserId ?? this.fromPeerUserId,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    isRead: isRead ?? this.isRead,
    replyToMessageId: replyToMessageId ?? this.replyToMessageId,
    forwarded: forwarded ?? this.forwarded,
    forwardedFromMessageId:
        forwardedFromMessageId ?? this.forwardedFromMessageId,
    attachmentsJson: attachmentsJson.present
        ? attachmentsJson.value
        : this.attachmentsJson,
    msgType: msgType ?? this.msgType,
    extraJson: extraJson.present ? extraJson.value : this.extraJson,
    codeLang: codeLang.present ? codeLang.value : this.codeLang,
    codeText: codeText.present ? codeText.value : this.codeText,
    locationLatitude: locationLatitude.present
        ? locationLatitude.value
        : this.locationLatitude,
    locationLongitude: locationLongitude.present
        ? locationLongitude.value
        : this.locationLongitude,
    locationDescription: locationDescription.present
        ? locationDescription.value
        : this.locationDescription,
    replyMarkupJson: replyMarkupJson.present
        ? replyMarkupJson.value
        : this.replyMarkupJson,
    pollJson: pollJson.present ? pollJson.value : this.pollJson,
  );
  CachedMessage copyWithCompanion(CachedMessagesCompanion data) {
    return CachedMessage(
      id: data.id.present ? data.id.value : this.id,
      isGroupChat: data.isGroupChat.present
          ? data.isGroupChat.value
          : this.isGroupChat,
      peerUserId: data.peerUserId.present
          ? data.peerUserId.value
          : this.peerUserId,
      peerGroupId: data.peerGroupId.present
          ? data.peerGroupId.value
          : this.peerGroupId,
      fromPeerUserId: data.fromPeerUserId.present
          ? data.fromPeerUserId.value
          : this.fromPeerUserId,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      replyToMessageId: data.replyToMessageId.present
          ? data.replyToMessageId.value
          : this.replyToMessageId,
      forwarded: data.forwarded.present ? data.forwarded.value : this.forwarded,
      forwardedFromMessageId: data.forwardedFromMessageId.present
          ? data.forwardedFromMessageId.value
          : this.forwardedFromMessageId,
      attachmentsJson: data.attachmentsJson.present
          ? data.attachmentsJson.value
          : this.attachmentsJson,
      msgType: data.msgType.present ? data.msgType.value : this.msgType,
      extraJson: data.extraJson.present ? data.extraJson.value : this.extraJson,
      codeLang: data.codeLang.present ? data.codeLang.value : this.codeLang,
      codeText: data.codeText.present ? data.codeText.value : this.codeText,
      locationLatitude: data.locationLatitude.present
          ? data.locationLatitude.value
          : this.locationLatitude,
      locationLongitude: data.locationLongitude.present
          ? data.locationLongitude.value
          : this.locationLongitude,
      locationDescription: data.locationDescription.present
          ? data.locationDescription.value
          : this.locationDescription,
      replyMarkupJson: data.replyMarkupJson.present
          ? data.replyMarkupJson.value
          : this.replyMarkupJson,
      pollJson: data.pollJson.present ? data.pollJson.value : this.pollJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMessage(')
          ..write('id: $id, ')
          ..write('isGroupChat: $isGroupChat, ')
          ..write('peerUserId: $peerUserId, ')
          ..write('peerGroupId: $peerGroupId, ')
          ..write('fromPeerUserId: $fromPeerUserId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('isRead: $isRead, ')
          ..write('replyToMessageId: $replyToMessageId, ')
          ..write('forwarded: $forwarded, ')
          ..write('forwardedFromMessageId: $forwardedFromMessageId, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('msgType: $msgType, ')
          ..write('extraJson: $extraJson, ')
          ..write('codeLang: $codeLang, ')
          ..write('codeText: $codeText, ')
          ..write('locationLatitude: $locationLatitude, ')
          ..write('locationLongitude: $locationLongitude, ')
          ..write('locationDescription: $locationDescription, ')
          ..write('replyMarkupJson: $replyMarkupJson, ')
          ..write('pollJson: $pollJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    isGroupChat,
    peerUserId,
    peerGroupId,
    fromPeerUserId,
    content,
    createdAt,
    isRead,
    replyToMessageId,
    forwarded,
    forwardedFromMessageId,
    attachmentsJson,
    msgType,
    extraJson,
    codeLang,
    codeText,
    locationLatitude,
    locationLongitude,
    locationDescription,
    replyMarkupJson,
    pollJson,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMessage &&
          other.id == this.id &&
          other.isGroupChat == this.isGroupChat &&
          other.peerUserId == this.peerUserId &&
          other.peerGroupId == this.peerGroupId &&
          other.fromPeerUserId == this.fromPeerUserId &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.isRead == this.isRead &&
          other.replyToMessageId == this.replyToMessageId &&
          other.forwarded == this.forwarded &&
          other.forwardedFromMessageId == this.forwardedFromMessageId &&
          other.attachmentsJson == this.attachmentsJson &&
          other.msgType == this.msgType &&
          other.extraJson == this.extraJson &&
          other.codeLang == this.codeLang &&
          other.codeText == this.codeText &&
          other.locationLatitude == this.locationLatitude &&
          other.locationLongitude == this.locationLongitude &&
          other.locationDescription == this.locationDescription &&
          other.replyMarkupJson == this.replyMarkupJson &&
          other.pollJson == this.pollJson);
}

class CachedMessagesCompanion extends UpdateCompanion<CachedMessage> {
  final Value<int> id;
  final Value<bool> isGroupChat;
  final Value<int> peerUserId;
  final Value<int> peerGroupId;
  final Value<int> fromPeerUserId;
  final Value<String> content;
  final Value<int> createdAt;
  final Value<bool> isRead;
  final Value<int> replyToMessageId;
  final Value<bool> forwarded;
  final Value<int> forwardedFromMessageId;
  final Value<String?> attachmentsJson;
  final Value<int> msgType;
  final Value<String?> extraJson;
  final Value<String?> codeLang;
  final Value<String?> codeText;
  final Value<String?> locationLatitude;
  final Value<String?> locationLongitude;
  final Value<String?> locationDescription;
  final Value<String?> replyMarkupJson;
  final Value<String?> pollJson;
  const CachedMessagesCompanion({
    this.id = const Value.absent(),
    this.isGroupChat = const Value.absent(),
    this.peerUserId = const Value.absent(),
    this.peerGroupId = const Value.absent(),
    this.fromPeerUserId = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isRead = const Value.absent(),
    this.replyToMessageId = const Value.absent(),
    this.forwarded = const Value.absent(),
    this.forwardedFromMessageId = const Value.absent(),
    this.attachmentsJson = const Value.absent(),
    this.msgType = const Value.absent(),
    this.extraJson = const Value.absent(),
    this.codeLang = const Value.absent(),
    this.codeText = const Value.absent(),
    this.locationLatitude = const Value.absent(),
    this.locationLongitude = const Value.absent(),
    this.locationDescription = const Value.absent(),
    this.replyMarkupJson = const Value.absent(),
    this.pollJson = const Value.absent(),
  });
  CachedMessagesCompanion.insert({
    this.id = const Value.absent(),
    this.isGroupChat = const Value.absent(),
    required int peerUserId,
    this.peerGroupId = const Value.absent(),
    required int fromPeerUserId,
    required String content,
    required int createdAt,
    this.isRead = const Value.absent(),
    this.replyToMessageId = const Value.absent(),
    this.forwarded = const Value.absent(),
    this.forwardedFromMessageId = const Value.absent(),
    this.attachmentsJson = const Value.absent(),
    this.msgType = const Value.absent(),
    this.extraJson = const Value.absent(),
    this.codeLang = const Value.absent(),
    this.codeText = const Value.absent(),
    this.locationLatitude = const Value.absent(),
    this.locationLongitude = const Value.absent(),
    this.locationDescription = const Value.absent(),
    this.replyMarkupJson = const Value.absent(),
    this.pollJson = const Value.absent(),
  }) : peerUserId = Value(peerUserId),
       fromPeerUserId = Value(fromPeerUserId),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<CachedMessage> custom({
    Expression<int>? id,
    Expression<bool>? isGroupChat,
    Expression<int>? peerUserId,
    Expression<int>? peerGroupId,
    Expression<int>? fromPeerUserId,
    Expression<String>? content,
    Expression<int>? createdAt,
    Expression<bool>? isRead,
    Expression<int>? replyToMessageId,
    Expression<bool>? forwarded,
    Expression<int>? forwardedFromMessageId,
    Expression<String>? attachmentsJson,
    Expression<int>? msgType,
    Expression<String>? extraJson,
    Expression<String>? codeLang,
    Expression<String>? codeText,
    Expression<String>? locationLatitude,
    Expression<String>? locationLongitude,
    Expression<String>? locationDescription,
    Expression<String>? replyMarkupJson,
    Expression<String>? pollJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isGroupChat != null) 'is_group_chat': isGroupChat,
      if (peerUserId != null) 'peer_user_id': peerUserId,
      if (peerGroupId != null) 'peer_group_id': peerGroupId,
      if (fromPeerUserId != null) 'from_peer_user_id': fromPeerUserId,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (isRead != null) 'is_read': isRead,
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      if (forwarded != null) 'forwarded': forwarded,
      if (forwardedFromMessageId != null)
        'forwarded_from_message_id': forwardedFromMessageId,
      if (attachmentsJson != null) 'attachments_json': attachmentsJson,
      if (msgType != null) 'msg_type': msgType,
      if (extraJson != null) 'extra_json': extraJson,
      if (codeLang != null) 'code_lang': codeLang,
      if (codeText != null) 'code_text': codeText,
      if (locationLatitude != null) 'location_latitude': locationLatitude,
      if (locationLongitude != null) 'location_longitude': locationLongitude,
      if (locationDescription != null)
        'location_description': locationDescription,
      if (replyMarkupJson != null) 'reply_markup_json': replyMarkupJson,
      if (pollJson != null) 'poll_json': pollJson,
    });
  }

  CachedMessagesCompanion copyWith({
    Value<int>? id,
    Value<bool>? isGroupChat,
    Value<int>? peerUserId,
    Value<int>? peerGroupId,
    Value<int>? fromPeerUserId,
    Value<String>? content,
    Value<int>? createdAt,
    Value<bool>? isRead,
    Value<int>? replyToMessageId,
    Value<bool>? forwarded,
    Value<int>? forwardedFromMessageId,
    Value<String?>? attachmentsJson,
    Value<int>? msgType,
    Value<String?>? extraJson,
    Value<String?>? codeLang,
    Value<String?>? codeText,
    Value<String?>? locationLatitude,
    Value<String?>? locationLongitude,
    Value<String?>? locationDescription,
    Value<String?>? replyMarkupJson,
    Value<String?>? pollJson,
  }) {
    return CachedMessagesCompanion(
      id: id ?? this.id,
      isGroupChat: isGroupChat ?? this.isGroupChat,
      peerUserId: peerUserId ?? this.peerUserId,
      peerGroupId: peerGroupId ?? this.peerGroupId,
      fromPeerUserId: fromPeerUserId ?? this.fromPeerUserId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      forwarded: forwarded ?? this.forwarded,
      forwardedFromMessageId:
          forwardedFromMessageId ?? this.forwardedFromMessageId,
      attachmentsJson: attachmentsJson ?? this.attachmentsJson,
      msgType: msgType ?? this.msgType,
      extraJson: extraJson ?? this.extraJson,
      codeLang: codeLang ?? this.codeLang,
      codeText: codeText ?? this.codeText,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      locationDescription: locationDescription ?? this.locationDescription,
      replyMarkupJson: replyMarkupJson ?? this.replyMarkupJson,
      pollJson: pollJson ?? this.pollJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (isGroupChat.present) {
      map['is_group_chat'] = Variable<bool>(isGroupChat.value);
    }
    if (peerUserId.present) {
      map['peer_user_id'] = Variable<int>(peerUserId.value);
    }
    if (peerGroupId.present) {
      map['peer_group_id'] = Variable<int>(peerGroupId.value);
    }
    if (fromPeerUserId.present) {
      map['from_peer_user_id'] = Variable<int>(fromPeerUserId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (replyToMessageId.present) {
      map['reply_to_message_id'] = Variable<int>(replyToMessageId.value);
    }
    if (forwarded.present) {
      map['forwarded'] = Variable<bool>(forwarded.value);
    }
    if (forwardedFromMessageId.present) {
      map['forwarded_from_message_id'] = Variable<int>(
        forwardedFromMessageId.value,
      );
    }
    if (attachmentsJson.present) {
      map['attachments_json'] = Variable<String>(attachmentsJson.value);
    }
    if (msgType.present) {
      map['msg_type'] = Variable<int>(msgType.value);
    }
    if (extraJson.present) {
      map['extra_json'] = Variable<String>(extraJson.value);
    }
    if (codeLang.present) {
      map['code_lang'] = Variable<String>(codeLang.value);
    }
    if (codeText.present) {
      map['code_text'] = Variable<String>(codeText.value);
    }
    if (locationLatitude.present) {
      map['location_latitude'] = Variable<String>(locationLatitude.value);
    }
    if (locationLongitude.present) {
      map['location_longitude'] = Variable<String>(locationLongitude.value);
    }
    if (locationDescription.present) {
      map['location_description'] = Variable<String>(locationDescription.value);
    }
    if (replyMarkupJson.present) {
      map['reply_markup_json'] = Variable<String>(replyMarkupJson.value);
    }
    if (pollJson.present) {
      map['poll_json'] = Variable<String>(pollJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMessagesCompanion(')
          ..write('id: $id, ')
          ..write('isGroupChat: $isGroupChat, ')
          ..write('peerUserId: $peerUserId, ')
          ..write('peerGroupId: $peerGroupId, ')
          ..write('fromPeerUserId: $fromPeerUserId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('isRead: $isRead, ')
          ..write('replyToMessageId: $replyToMessageId, ')
          ..write('forwarded: $forwarded, ')
          ..write('forwardedFromMessageId: $forwardedFromMessageId, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('msgType: $msgType, ')
          ..write('extraJson: $extraJson, ')
          ..write('codeLang: $codeLang, ')
          ..write('codeText: $codeText, ')
          ..write('locationLatitude: $locationLatitude, ')
          ..write('locationLongitude: $locationLongitude, ')
          ..write('locationDescription: $locationDescription, ')
          ..write('replyMarkupJson: $replyMarkupJson, ')
          ..write('pollJson: $pollJson')
          ..write(')'))
        .toString();
  }
}

class $CachedChatsTable extends CachedChats
    with TableInfo<$CachedChatsTable, CachedChat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedChatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isGroupMeta = const VerificationMeta(
    'isGroup',
  );
  @override
  late final GeneratedColumn<bool> isGroup = GeneratedColumn<bool>(
    'is_group',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_group" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _peerUserIdMeta = const VerificationMeta(
    'peerUserId',
  );
  @override
  late final GeneratedColumn<int> peerUserId = GeneratedColumn<int>(
    'peer_user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerGroupIdMeta = const VerificationMeta(
    'peerGroupId',
  );
  @override
  late final GeneratedColumn<int> peerGroupId = GeneratedColumn<int>(
    'peer_group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userUsernameMeta = const VerificationMeta(
    'userUsername',
  );
  @override
  late final GeneratedColumn<String> userUsername = GeneratedColumn<String>(
    'user_username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _userNameMeta = const VerificationMeta(
    'userName',
  );
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
    'user_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _userSurnameMeta = const VerificationMeta(
    'userSurname',
  );
  @override
  late final GeneratedColumn<String> userSurname = GeneratedColumn<String>(
    'user_surname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _memberCountMeta = const VerificationMeta(
    'memberCount',
  );
  @override
  late final GeneratedColumn<int> memberCount = GeneratedColumn<int>(
    'member_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _photoIdMeta = const VerificationMeta(
    'photoId',
  );
  @override
  late final GeneratedColumn<String> photoId = GeneratedColumn<String>(
    'photo_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessagePreviewMeta =
      const VerificationMeta('lastMessagePreview');
  @override
  late final GeneratedColumn<String> lastMessagePreview =
      GeneratedColumn<String>(
        'last_message_preview',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notificationsMutedMeta =
      const VerificationMeta('notificationsMuted');
  @override
  late final GeneratedColumn<bool> notificationsMuted = GeneratedColumn<bool>(
    'notifications_muted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notifications_muted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<int> listId = GeneratedColumn<int>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isGroup,
    peerUserId,
    peerGroupId,
    title,
    userUsername,
    userName,
    userSurname,
    updatedAt,
    unreadCount,
    memberCount,
    photoId,
    lastMessagePreview,
    notificationsMuted,
    listId,
    isPinned,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_chats';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedChat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('is_group')) {
      context.handle(
        _isGroupMeta,
        isGroup.isAcceptableOrUnknown(data['is_group']!, _isGroupMeta),
      );
    }
    if (data.containsKey('peer_user_id')) {
      context.handle(
        _peerUserIdMeta,
        peerUserId.isAcceptableOrUnknown(
          data['peer_user_id']!,
          _peerUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peerUserIdMeta);
    }
    if (data.containsKey('peer_group_id')) {
      context.handle(
        _peerGroupIdMeta,
        peerGroupId.isAcceptableOrUnknown(
          data['peer_group_id']!,
          _peerGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('user_username')) {
      context.handle(
        _userUsernameMeta,
        userUsername.isAcceptableOrUnknown(
          data['user_username']!,
          _userUsernameMeta,
        ),
      );
    }
    if (data.containsKey('user_name')) {
      context.handle(
        _userNameMeta,
        userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta),
      );
    }
    if (data.containsKey('user_surname')) {
      context.handle(
        _userSurnameMeta,
        userSurname.isAcceptableOrUnknown(
          data['user_surname']!,
          _userSurnameMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('member_count')) {
      context.handle(
        _memberCountMeta,
        memberCount.isAcceptableOrUnknown(
          data['member_count']!,
          _memberCountMeta,
        ),
      );
    }
    if (data.containsKey('photo_id')) {
      context.handle(
        _photoIdMeta,
        photoId.isAcceptableOrUnknown(data['photo_id']!, _photoIdMeta),
      );
    }
    if (data.containsKey('last_message_preview')) {
      context.handle(
        _lastMessagePreviewMeta,
        lastMessagePreview.isAcceptableOrUnknown(
          data['last_message_preview']!,
          _lastMessagePreviewMeta,
        ),
      );
    }
    if (data.containsKey('notifications_muted')) {
      context.handle(
        _notificationsMutedMeta,
        notificationsMuted.isAcceptableOrUnknown(
          data['notifications_muted']!,
          _notificationsMutedMeta,
        ),
      );
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedChat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedChat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      isGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_group'],
      )!,
      peerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}peer_user_id'],
      )!,
      peerGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}peer_group_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      userUsername: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_username'],
      )!,
      userName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_name'],
      )!,
      userSurname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_surname'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      memberCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_count'],
      )!,
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_id'],
      ),
      lastMessagePreview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_preview'],
      ),
      notificationsMuted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notifications_muted'],
      )!,
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}list_id'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
    );
  }

  @override
  $CachedChatsTable createAlias(String alias) {
    return $CachedChatsTable(attachedDatabase, alias);
  }
}

class CachedChat extends DataClass implements Insertable<CachedChat> {
  final int id;
  final bool isGroup;
  final int peerUserId;
  final int peerGroupId;
  final String title;
  final String userUsername;
  final String userName;
  final String userSurname;
  final int updatedAt;
  final int unreadCount;
  final int memberCount;
  final String? photoId;
  final String? lastMessagePreview;
  final bool notificationsMuted;
  final int listId;
  final bool isPinned;
  const CachedChat({
    required this.id,
    required this.isGroup,
    required this.peerUserId,
    required this.peerGroupId,
    required this.title,
    required this.userUsername,
    required this.userName,
    required this.userSurname,
    required this.updatedAt,
    required this.unreadCount,
    required this.memberCount,
    this.photoId,
    this.lastMessagePreview,
    required this.notificationsMuted,
    required this.listId,
    required this.isPinned,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['is_group'] = Variable<bool>(isGroup);
    map['peer_user_id'] = Variable<int>(peerUserId);
    map['peer_group_id'] = Variable<int>(peerGroupId);
    map['title'] = Variable<String>(title);
    map['user_username'] = Variable<String>(userUsername);
    map['user_name'] = Variable<String>(userName);
    map['user_surname'] = Variable<String>(userSurname);
    map['updated_at'] = Variable<int>(updatedAt);
    map['unread_count'] = Variable<int>(unreadCount);
    map['member_count'] = Variable<int>(memberCount);
    if (!nullToAbsent || photoId != null) {
      map['photo_id'] = Variable<String>(photoId);
    }
    if (!nullToAbsent || lastMessagePreview != null) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview);
    }
    map['notifications_muted'] = Variable<bool>(notificationsMuted);
    map['list_id'] = Variable<int>(listId);
    map['is_pinned'] = Variable<bool>(isPinned);
    return map;
  }

  CachedChatsCompanion toCompanion(bool nullToAbsent) {
    return CachedChatsCompanion(
      id: Value(id),
      isGroup: Value(isGroup),
      peerUserId: Value(peerUserId),
      peerGroupId: Value(peerGroupId),
      title: Value(title),
      userUsername: Value(userUsername),
      userName: Value(userName),
      userSurname: Value(userSurname),
      updatedAt: Value(updatedAt),
      unreadCount: Value(unreadCount),
      memberCount: Value(memberCount),
      photoId: photoId == null && nullToAbsent
          ? const Value.absent()
          : Value(photoId),
      lastMessagePreview: lastMessagePreview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessagePreview),
      notificationsMuted: Value(notificationsMuted),
      listId: Value(listId),
      isPinned: Value(isPinned),
    );
  }

  factory CachedChat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedChat(
      id: serializer.fromJson<int>(json['id']),
      isGroup: serializer.fromJson<bool>(json['isGroup']),
      peerUserId: serializer.fromJson<int>(json['peerUserId']),
      peerGroupId: serializer.fromJson<int>(json['peerGroupId']),
      title: serializer.fromJson<String>(json['title']),
      userUsername: serializer.fromJson<String>(json['userUsername']),
      userName: serializer.fromJson<String>(json['userName']),
      userSurname: serializer.fromJson<String>(json['userSurname']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      memberCount: serializer.fromJson<int>(json['memberCount']),
      photoId: serializer.fromJson<String?>(json['photoId']),
      lastMessagePreview: serializer.fromJson<String?>(
        json['lastMessagePreview'],
      ),
      notificationsMuted: serializer.fromJson<bool>(json['notificationsMuted']),
      listId: serializer.fromJson<int>(json['listId']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'isGroup': serializer.toJson<bool>(isGroup),
      'peerUserId': serializer.toJson<int>(peerUserId),
      'peerGroupId': serializer.toJson<int>(peerGroupId),
      'title': serializer.toJson<String>(title),
      'userUsername': serializer.toJson<String>(userUsername),
      'userName': serializer.toJson<String>(userName),
      'userSurname': serializer.toJson<String>(userSurname),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'memberCount': serializer.toJson<int>(memberCount),
      'photoId': serializer.toJson<String?>(photoId),
      'lastMessagePreview': serializer.toJson<String?>(lastMessagePreview),
      'notificationsMuted': serializer.toJson<bool>(notificationsMuted),
      'listId': serializer.toJson<int>(listId),
      'isPinned': serializer.toJson<bool>(isPinned),
    };
  }

  CachedChat copyWith({
    int? id,
    bool? isGroup,
    int? peerUserId,
    int? peerGroupId,
    String? title,
    String? userUsername,
    String? userName,
    String? userSurname,
    int? updatedAt,
    int? unreadCount,
    int? memberCount,
    Value<String?> photoId = const Value.absent(),
    Value<String?> lastMessagePreview = const Value.absent(),
    bool? notificationsMuted,
    int? listId,
    bool? isPinned,
  }) => CachedChat(
    id: id ?? this.id,
    isGroup: isGroup ?? this.isGroup,
    peerUserId: peerUserId ?? this.peerUserId,
    peerGroupId: peerGroupId ?? this.peerGroupId,
    title: title ?? this.title,
    userUsername: userUsername ?? this.userUsername,
    userName: userName ?? this.userName,
    userSurname: userSurname ?? this.userSurname,
    updatedAt: updatedAt ?? this.updatedAt,
    unreadCount: unreadCount ?? this.unreadCount,
    memberCount: memberCount ?? this.memberCount,
    photoId: photoId.present ? photoId.value : this.photoId,
    lastMessagePreview: lastMessagePreview.present
        ? lastMessagePreview.value
        : this.lastMessagePreview,
    notificationsMuted: notificationsMuted ?? this.notificationsMuted,
    listId: listId ?? this.listId,
    isPinned: isPinned ?? this.isPinned,
  );
  CachedChat copyWithCompanion(CachedChatsCompanion data) {
    return CachedChat(
      id: data.id.present ? data.id.value : this.id,
      isGroup: data.isGroup.present ? data.isGroup.value : this.isGroup,
      peerUserId: data.peerUserId.present
          ? data.peerUserId.value
          : this.peerUserId,
      peerGroupId: data.peerGroupId.present
          ? data.peerGroupId.value
          : this.peerGroupId,
      title: data.title.present ? data.title.value : this.title,
      userUsername: data.userUsername.present
          ? data.userUsername.value
          : this.userUsername,
      userName: data.userName.present ? data.userName.value : this.userName,
      userSurname: data.userSurname.present
          ? data.userSurname.value
          : this.userSurname,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      memberCount: data.memberCount.present
          ? data.memberCount.value
          : this.memberCount,
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      lastMessagePreview: data.lastMessagePreview.present
          ? data.lastMessagePreview.value
          : this.lastMessagePreview,
      notificationsMuted: data.notificationsMuted.present
          ? data.notificationsMuted.value
          : this.notificationsMuted,
      listId: data.listId.present ? data.listId.value : this.listId,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedChat(')
          ..write('id: $id, ')
          ..write('isGroup: $isGroup, ')
          ..write('peerUserId: $peerUserId, ')
          ..write('peerGroupId: $peerGroupId, ')
          ..write('title: $title, ')
          ..write('userUsername: $userUsername, ')
          ..write('userName: $userName, ')
          ..write('userSurname: $userSurname, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('memberCount: $memberCount, ')
          ..write('photoId: $photoId, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('notificationsMuted: $notificationsMuted, ')
          ..write('listId: $listId, ')
          ..write('isPinned: $isPinned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    isGroup,
    peerUserId,
    peerGroupId,
    title,
    userUsername,
    userName,
    userSurname,
    updatedAt,
    unreadCount,
    memberCount,
    photoId,
    lastMessagePreview,
    notificationsMuted,
    listId,
    isPinned,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedChat &&
          other.id == this.id &&
          other.isGroup == this.isGroup &&
          other.peerUserId == this.peerUserId &&
          other.peerGroupId == this.peerGroupId &&
          other.title == this.title &&
          other.userUsername == this.userUsername &&
          other.userName == this.userName &&
          other.userSurname == this.userSurname &&
          other.updatedAt == this.updatedAt &&
          other.unreadCount == this.unreadCount &&
          other.memberCount == this.memberCount &&
          other.photoId == this.photoId &&
          other.lastMessagePreview == this.lastMessagePreview &&
          other.notificationsMuted == this.notificationsMuted &&
          other.listId == this.listId &&
          other.isPinned == this.isPinned);
}

class CachedChatsCompanion extends UpdateCompanion<CachedChat> {
  final Value<int> id;
  final Value<bool> isGroup;
  final Value<int> peerUserId;
  final Value<int> peerGroupId;
  final Value<String> title;
  final Value<String> userUsername;
  final Value<String> userName;
  final Value<String> userSurname;
  final Value<int> updatedAt;
  final Value<int> unreadCount;
  final Value<int> memberCount;
  final Value<String?> photoId;
  final Value<String?> lastMessagePreview;
  final Value<bool> notificationsMuted;
  final Value<int> listId;
  final Value<bool> isPinned;
  const CachedChatsCompanion({
    this.id = const Value.absent(),
    this.isGroup = const Value.absent(),
    this.peerUserId = const Value.absent(),
    this.peerGroupId = const Value.absent(),
    this.title = const Value.absent(),
    this.userUsername = const Value.absent(),
    this.userName = const Value.absent(),
    this.userSurname = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.memberCount = const Value.absent(),
    this.photoId = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.notificationsMuted = const Value.absent(),
    this.listId = const Value.absent(),
    this.isPinned = const Value.absent(),
  });
  CachedChatsCompanion.insert({
    this.id = const Value.absent(),
    this.isGroup = const Value.absent(),
    required int peerUserId,
    this.peerGroupId = const Value.absent(),
    required String title,
    this.userUsername = const Value.absent(),
    this.userName = const Value.absent(),
    this.userSurname = const Value.absent(),
    required int updatedAt,
    this.unreadCount = const Value.absent(),
    this.memberCount = const Value.absent(),
    this.photoId = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.notificationsMuted = const Value.absent(),
    this.listId = const Value.absent(),
    this.isPinned = const Value.absent(),
  }) : peerUserId = Value(peerUserId),
       title = Value(title),
       updatedAt = Value(updatedAt);
  static Insertable<CachedChat> custom({
    Expression<int>? id,
    Expression<bool>? isGroup,
    Expression<int>? peerUserId,
    Expression<int>? peerGroupId,
    Expression<String>? title,
    Expression<String>? userUsername,
    Expression<String>? userName,
    Expression<String>? userSurname,
    Expression<int>? updatedAt,
    Expression<int>? unreadCount,
    Expression<int>? memberCount,
    Expression<String>? photoId,
    Expression<String>? lastMessagePreview,
    Expression<bool>? notificationsMuted,
    Expression<int>? listId,
    Expression<bool>? isPinned,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isGroup != null) 'is_group': isGroup,
      if (peerUserId != null) 'peer_user_id': peerUserId,
      if (peerGroupId != null) 'peer_group_id': peerGroupId,
      if (title != null) 'title': title,
      if (userUsername != null) 'user_username': userUsername,
      if (userName != null) 'user_name': userName,
      if (userSurname != null) 'user_surname': userSurname,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (memberCount != null) 'member_count': memberCount,
      if (photoId != null) 'photo_id': photoId,
      if (lastMessagePreview != null)
        'last_message_preview': lastMessagePreview,
      if (notificationsMuted != null) 'notifications_muted': notificationsMuted,
      if (listId != null) 'list_id': listId,
      if (isPinned != null) 'is_pinned': isPinned,
    });
  }

  CachedChatsCompanion copyWith({
    Value<int>? id,
    Value<bool>? isGroup,
    Value<int>? peerUserId,
    Value<int>? peerGroupId,
    Value<String>? title,
    Value<String>? userUsername,
    Value<String>? userName,
    Value<String>? userSurname,
    Value<int>? updatedAt,
    Value<int>? unreadCount,
    Value<int>? memberCount,
    Value<String?>? photoId,
    Value<String?>? lastMessagePreview,
    Value<bool>? notificationsMuted,
    Value<int>? listId,
    Value<bool>? isPinned,
  }) {
    return CachedChatsCompanion(
      id: id ?? this.id,
      isGroup: isGroup ?? this.isGroup,
      peerUserId: peerUserId ?? this.peerUserId,
      peerGroupId: peerGroupId ?? this.peerGroupId,
      title: title ?? this.title,
      userUsername: userUsername ?? this.userUsername,
      userName: userName ?? this.userName,
      userSurname: userSurname ?? this.userSurname,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      memberCount: memberCount ?? this.memberCount,
      photoId: photoId ?? this.photoId,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      notificationsMuted: notificationsMuted ?? this.notificationsMuted,
      listId: listId ?? this.listId,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (isGroup.present) {
      map['is_group'] = Variable<bool>(isGroup.value);
    }
    if (peerUserId.present) {
      map['peer_user_id'] = Variable<int>(peerUserId.value);
    }
    if (peerGroupId.present) {
      map['peer_group_id'] = Variable<int>(peerGroupId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (userUsername.present) {
      map['user_username'] = Variable<String>(userUsername.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (userSurname.present) {
      map['user_surname'] = Variable<String>(userSurname.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (memberCount.present) {
      map['member_count'] = Variable<int>(memberCount.value);
    }
    if (photoId.present) {
      map['photo_id'] = Variable<String>(photoId.value);
    }
    if (lastMessagePreview.present) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview.value);
    }
    if (notificationsMuted.present) {
      map['notifications_muted'] = Variable<bool>(notificationsMuted.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<int>(listId.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedChatsCompanion(')
          ..write('id: $id, ')
          ..write('isGroup: $isGroup, ')
          ..write('peerUserId: $peerUserId, ')
          ..write('peerGroupId: $peerGroupId, ')
          ..write('title: $title, ')
          ..write('userUsername: $userUsername, ')
          ..write('userName: $userName, ')
          ..write('userSurname: $userSurname, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('memberCount: $memberCount, ')
          ..write('photoId: $photoId, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('notificationsMuted: $notificationsMuted, ')
          ..write('listId: $listId, ')
          ..write('isPinned: $isPinned')
          ..write(')'))
        .toString();
  }
}

class $PendingOutgoingMessagesTable extends PendingOutgoingMessages
    with TableInfo<$PendingOutgoingMessagesTable, PendingOutgoingMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingOutgoingMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerUserIdMeta = const VerificationMeta(
    'peerUserId',
  );
  @override
  late final GeneratedColumn<int> peerUserId = GeneratedColumn<int>(
    'peer_user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerGroupIdMeta = const VerificationMeta(
    'peerGroupId',
  );
  @override
  late final GeneratedColumn<int> peerGroupId = GeneratedColumn<int>(
    'peer_group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attachmentsJsonMeta = const VerificationMeta(
    'attachmentsJson',
  );
  @override
  late final GeneratedColumn<String> attachmentsJson = GeneratedColumn<String>(
    'attachments_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replyToIdMeta = const VerificationMeta(
    'replyToId',
  );
  @override
  late final GeneratedColumn<int> replyToId = GeneratedColumn<int>(
    'reply_to_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    peerUserId,
    peerGroupId,
    content,
    attachmentsJson,
    replyToId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_outgoing_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingOutgoingMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('peer_user_id')) {
      context.handle(
        _peerUserIdMeta,
        peerUserId.isAcceptableOrUnknown(
          data['peer_user_id']!,
          _peerUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peerUserIdMeta);
    }
    if (data.containsKey('peer_group_id')) {
      context.handle(
        _peerGroupIdMeta,
        peerGroupId.isAcceptableOrUnknown(
          data['peer_group_id']!,
          _peerGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('attachments_json')) {
      context.handle(
        _attachmentsJsonMeta,
        attachmentsJson.isAcceptableOrUnknown(
          data['attachments_json']!,
          _attachmentsJsonMeta,
        ),
      );
    }
    if (data.containsKey('reply_to_id')) {
      context.handle(
        _replyToIdMeta,
        replyToId.isAcceptableOrUnknown(data['reply_to_id']!, _replyToIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  PendingOutgoingMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOutgoingMessage(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      peerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}peer_user_id'],
      )!,
      peerGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}peer_group_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      attachmentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachments_json'],
      ),
      replyToId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reply_to_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingOutgoingMessagesTable createAlias(String alias) {
    return $PendingOutgoingMessagesTable(attachedDatabase, alias);
  }
}

class PendingOutgoingMessage extends DataClass
    implements Insertable<PendingOutgoingMessage> {
  final String localId;
  final int peerUserId;
  final int peerGroupId;
  final String content;
  final String? attachmentsJson;
  final int replyToId;
  final int createdAt;
  const PendingOutgoingMessage({
    required this.localId,
    required this.peerUserId,
    required this.peerGroupId,
    required this.content,
    this.attachmentsJson,
    required this.replyToId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['peer_user_id'] = Variable<int>(peerUserId);
    map['peer_group_id'] = Variable<int>(peerGroupId);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || attachmentsJson != null) {
      map['attachments_json'] = Variable<String>(attachmentsJson);
    }
    map['reply_to_id'] = Variable<int>(replyToId);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PendingOutgoingMessagesCompanion toCompanion(bool nullToAbsent) {
    return PendingOutgoingMessagesCompanion(
      localId: Value(localId),
      peerUserId: Value(peerUserId),
      peerGroupId: Value(peerGroupId),
      content: Value(content),
      attachmentsJson: attachmentsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentsJson),
      replyToId: Value(replyToId),
      createdAt: Value(createdAt),
    );
  }

  factory PendingOutgoingMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOutgoingMessage(
      localId: serializer.fromJson<String>(json['localId']),
      peerUserId: serializer.fromJson<int>(json['peerUserId']),
      peerGroupId: serializer.fromJson<int>(json['peerGroupId']),
      content: serializer.fromJson<String>(json['content']),
      attachmentsJson: serializer.fromJson<String?>(json['attachmentsJson']),
      replyToId: serializer.fromJson<int>(json['replyToId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'peerUserId': serializer.toJson<int>(peerUserId),
      'peerGroupId': serializer.toJson<int>(peerGroupId),
      'content': serializer.toJson<String>(content),
      'attachmentsJson': serializer.toJson<String?>(attachmentsJson),
      'replyToId': serializer.toJson<int>(replyToId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PendingOutgoingMessage copyWith({
    String? localId,
    int? peerUserId,
    int? peerGroupId,
    String? content,
    Value<String?> attachmentsJson = const Value.absent(),
    int? replyToId,
    int? createdAt,
  }) => PendingOutgoingMessage(
    localId: localId ?? this.localId,
    peerUserId: peerUserId ?? this.peerUserId,
    peerGroupId: peerGroupId ?? this.peerGroupId,
    content: content ?? this.content,
    attachmentsJson: attachmentsJson.present
        ? attachmentsJson.value
        : this.attachmentsJson,
    replyToId: replyToId ?? this.replyToId,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingOutgoingMessage copyWithCompanion(
    PendingOutgoingMessagesCompanion data,
  ) {
    return PendingOutgoingMessage(
      localId: data.localId.present ? data.localId.value : this.localId,
      peerUserId: data.peerUserId.present
          ? data.peerUserId.value
          : this.peerUserId,
      peerGroupId: data.peerGroupId.present
          ? data.peerGroupId.value
          : this.peerGroupId,
      content: data.content.present ? data.content.value : this.content,
      attachmentsJson: data.attachmentsJson.present
          ? data.attachmentsJson.value
          : this.attachmentsJson,
      replyToId: data.replyToId.present ? data.replyToId.value : this.replyToId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOutgoingMessage(')
          ..write('localId: $localId, ')
          ..write('peerUserId: $peerUserId, ')
          ..write('peerGroupId: $peerGroupId, ')
          ..write('content: $content, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('replyToId: $replyToId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    peerUserId,
    peerGroupId,
    content,
    attachmentsJson,
    replyToId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOutgoingMessage &&
          other.localId == this.localId &&
          other.peerUserId == this.peerUserId &&
          other.peerGroupId == this.peerGroupId &&
          other.content == this.content &&
          other.attachmentsJson == this.attachmentsJson &&
          other.replyToId == this.replyToId &&
          other.createdAt == this.createdAt);
}

class PendingOutgoingMessagesCompanion
    extends UpdateCompanion<PendingOutgoingMessage> {
  final Value<String> localId;
  final Value<int> peerUserId;
  final Value<int> peerGroupId;
  final Value<String> content;
  final Value<String?> attachmentsJson;
  final Value<int> replyToId;
  final Value<int> createdAt;
  final Value<int> rowid;
  const PendingOutgoingMessagesCompanion({
    this.localId = const Value.absent(),
    this.peerUserId = const Value.absent(),
    this.peerGroupId = const Value.absent(),
    this.content = const Value.absent(),
    this.attachmentsJson = const Value.absent(),
    this.replyToId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingOutgoingMessagesCompanion.insert({
    required String localId,
    required int peerUserId,
    this.peerGroupId = const Value.absent(),
    required String content,
    this.attachmentsJson = const Value.absent(),
    this.replyToId = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       peerUserId = Value(peerUserId),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<PendingOutgoingMessage> custom({
    Expression<String>? localId,
    Expression<int>? peerUserId,
    Expression<int>? peerGroupId,
    Expression<String>? content,
    Expression<String>? attachmentsJson,
    Expression<int>? replyToId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (peerUserId != null) 'peer_user_id': peerUserId,
      if (peerGroupId != null) 'peer_group_id': peerGroupId,
      if (content != null) 'content': content,
      if (attachmentsJson != null) 'attachments_json': attachmentsJson,
      if (replyToId != null) 'reply_to_id': replyToId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingOutgoingMessagesCompanion copyWith({
    Value<String>? localId,
    Value<int>? peerUserId,
    Value<int>? peerGroupId,
    Value<String>? content,
    Value<String?>? attachmentsJson,
    Value<int>? replyToId,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return PendingOutgoingMessagesCompanion(
      localId: localId ?? this.localId,
      peerUserId: peerUserId ?? this.peerUserId,
      peerGroupId: peerGroupId ?? this.peerGroupId,
      content: content ?? this.content,
      attachmentsJson: attachmentsJson ?? this.attachmentsJson,
      replyToId: replyToId ?? this.replyToId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (peerUserId.present) {
      map['peer_user_id'] = Variable<int>(peerUserId.value);
    }
    if (peerGroupId.present) {
      map['peer_group_id'] = Variable<int>(peerGroupId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (attachmentsJson.present) {
      map['attachments_json'] = Variable<String>(attachmentsJson.value);
    }
    if (replyToId.present) {
      map['reply_to_id'] = Variable<int>(replyToId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOutgoingMessagesCompanion(')
          ..write('localId: $localId, ')
          ..write('peerUserId: $peerUserId, ')
          ..write('peerGroupId: $peerGroupId, ')
          ..write('content: $content, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('replyToId: $replyToId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SyncStatesTable syncStates = $SyncStatesTable(this);
  late final $CachedMessagesTable cachedMessages = $CachedMessagesTable(this);
  late final $CachedChatsTable cachedChats = $CachedChatsTable(this);
  late final $PendingOutgoingMessagesTable pendingOutgoingMessages =
      $PendingOutgoingMessagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    syncStates,
    cachedMessages,
    cachedChats,
    pendingOutgoingMessages,
  ];
}

typedef $$SyncStatesTableCreateCompanionBuilder =
    SyncStatesCompanion Function({
      Value<int> id,
      Value<int> pts,
      Value<int> date,
    });
typedef $$SyncStatesTableUpdateCompanionBuilder =
    SyncStatesCompanion Function({
      Value<int> id,
      Value<int> pts,
      Value<int> date,
    });

class $$SyncStatesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pts => $composableBuilder(
    column: $table.pts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pts => $composableBuilder(
    column: $table.pts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get pts =>
      $composableBuilder(column: $table.pts, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);
}

class $$SyncStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStatesTable,
          SyncState,
          $$SyncStatesTableFilterComposer,
          $$SyncStatesTableOrderingComposer,
          $$SyncStatesTableAnnotationComposer,
          $$SyncStatesTableCreateCompanionBuilder,
          $$SyncStatesTableUpdateCompanionBuilder,
          (
            SyncState,
            BaseReferences<_$AppDatabase, $SyncStatesTable, SyncState>,
          ),
          SyncState,
          PrefetchHooks Function()
        > {
  $$SyncStatesTableTableManager(_$AppDatabase db, $SyncStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> pts = const Value.absent(),
                Value<int> date = const Value.absent(),
              }) => SyncStatesCompanion(id: id, pts: pts, date: date),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> pts = const Value.absent(),
                Value<int> date = const Value.absent(),
              }) => SyncStatesCompanion.insert(id: id, pts: pts, date: date),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStatesTable,
      SyncState,
      $$SyncStatesTableFilterComposer,
      $$SyncStatesTableOrderingComposer,
      $$SyncStatesTableAnnotationComposer,
      $$SyncStatesTableCreateCompanionBuilder,
      $$SyncStatesTableUpdateCompanionBuilder,
      (SyncState, BaseReferences<_$AppDatabase, $SyncStatesTable, SyncState>),
      SyncState,
      PrefetchHooks Function()
    >;
typedef $$CachedMessagesTableCreateCompanionBuilder =
    CachedMessagesCompanion Function({
      Value<int> id,
      Value<bool> isGroupChat,
      required int peerUserId,
      Value<int> peerGroupId,
      required int fromPeerUserId,
      required String content,
      required int createdAt,
      Value<bool> isRead,
      Value<int> replyToMessageId,
      Value<bool> forwarded,
      Value<int> forwardedFromMessageId,
      Value<String?> attachmentsJson,
      Value<int> msgType,
      Value<String?> extraJson,
      Value<String?> codeLang,
      Value<String?> codeText,
      Value<String?> locationLatitude,
      Value<String?> locationLongitude,
      Value<String?> locationDescription,
      Value<String?> replyMarkupJson,
      Value<String?> pollJson,
    });
typedef $$CachedMessagesTableUpdateCompanionBuilder =
    CachedMessagesCompanion Function({
      Value<int> id,
      Value<bool> isGroupChat,
      Value<int> peerUserId,
      Value<int> peerGroupId,
      Value<int> fromPeerUserId,
      Value<String> content,
      Value<int> createdAt,
      Value<bool> isRead,
      Value<int> replyToMessageId,
      Value<bool> forwarded,
      Value<int> forwardedFromMessageId,
      Value<String?> attachmentsJson,
      Value<int> msgType,
      Value<String?> extraJson,
      Value<String?> codeLang,
      Value<String?> codeText,
      Value<String?> locationLatitude,
      Value<String?> locationLongitude,
      Value<String?> locationDescription,
      Value<String?> replyMarkupJson,
      Value<String?> pollJson,
    });

class $$CachedMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedMessagesTable> {
  $$CachedMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isGroupChat => $composableBuilder(
    column: $table.isGroupChat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get peerGroupId => $composableBuilder(
    column: $table.peerGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fromPeerUserId => $composableBuilder(
    column: $table.fromPeerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get replyToMessageId => $composableBuilder(
    column: $table.replyToMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get forwarded => $composableBuilder(
    column: $table.forwarded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get forwardedFromMessageId => $composableBuilder(
    column: $table.forwardedFromMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get msgType => $composableBuilder(
    column: $table.msgType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extraJson => $composableBuilder(
    column: $table.extraJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codeLang => $composableBuilder(
    column: $table.codeLang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codeText => $composableBuilder(
    column: $table.codeText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationLatitude => $composableBuilder(
    column: $table.locationLatitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationLongitude => $composableBuilder(
    column: $table.locationLongitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationDescription => $composableBuilder(
    column: $table.locationDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyMarkupJson => $composableBuilder(
    column: $table.replyMarkupJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pollJson => $composableBuilder(
    column: $table.pollJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedMessagesTable> {
  $$CachedMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGroupChat => $composableBuilder(
    column: $table.isGroupChat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get peerGroupId => $composableBuilder(
    column: $table.peerGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fromPeerUserId => $composableBuilder(
    column: $table.fromPeerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get replyToMessageId => $composableBuilder(
    column: $table.replyToMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get forwarded => $composableBuilder(
    column: $table.forwarded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get forwardedFromMessageId => $composableBuilder(
    column: $table.forwardedFromMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get msgType => $composableBuilder(
    column: $table.msgType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extraJson => $composableBuilder(
    column: $table.extraJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codeLang => $composableBuilder(
    column: $table.codeLang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codeText => $composableBuilder(
    column: $table.codeText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationLatitude => $composableBuilder(
    column: $table.locationLatitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationLongitude => $composableBuilder(
    column: $table.locationLongitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationDescription => $composableBuilder(
    column: $table.locationDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyMarkupJson => $composableBuilder(
    column: $table.replyMarkupJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pollJson => $composableBuilder(
    column: $table.pollJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedMessagesTable> {
  $$CachedMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isGroupChat => $composableBuilder(
    column: $table.isGroupChat,
    builder: (column) => column,
  );

  GeneratedColumn<int> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get peerGroupId => $composableBuilder(
    column: $table.peerGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fromPeerUserId => $composableBuilder(
    column: $table.fromPeerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<int> get replyToMessageId => $composableBuilder(
    column: $table.replyToMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get forwarded =>
      $composableBuilder(column: $table.forwarded, builder: (column) => column);

  GeneratedColumn<int> get forwardedFromMessageId => $composableBuilder(
    column: $table.forwardedFromMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get msgType =>
      $composableBuilder(column: $table.msgType, builder: (column) => column);

  GeneratedColumn<String> get extraJson =>
      $composableBuilder(column: $table.extraJson, builder: (column) => column);

  GeneratedColumn<String> get codeLang =>
      $composableBuilder(column: $table.codeLang, builder: (column) => column);

  GeneratedColumn<String> get codeText =>
      $composableBuilder(column: $table.codeText, builder: (column) => column);

  GeneratedColumn<String> get locationLatitude => $composableBuilder(
    column: $table.locationLatitude,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locationLongitude => $composableBuilder(
    column: $table.locationLongitude,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locationDescription => $composableBuilder(
    column: $table.locationDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replyMarkupJson => $composableBuilder(
    column: $table.replyMarkupJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pollJson =>
      $composableBuilder(column: $table.pollJson, builder: (column) => column);
}

class $$CachedMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedMessagesTable,
          CachedMessage,
          $$CachedMessagesTableFilterComposer,
          $$CachedMessagesTableOrderingComposer,
          $$CachedMessagesTableAnnotationComposer,
          $$CachedMessagesTableCreateCompanionBuilder,
          $$CachedMessagesTableUpdateCompanionBuilder,
          (
            CachedMessage,
            BaseReferences<_$AppDatabase, $CachedMessagesTable, CachedMessage>,
          ),
          CachedMessage,
          PrefetchHooks Function()
        > {
  $$CachedMessagesTableTableManager(
    _$AppDatabase db,
    $CachedMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> isGroupChat = const Value.absent(),
                Value<int> peerUserId = const Value.absent(),
                Value<int> peerGroupId = const Value.absent(),
                Value<int> fromPeerUserId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<int> replyToMessageId = const Value.absent(),
                Value<bool> forwarded = const Value.absent(),
                Value<int> forwardedFromMessageId = const Value.absent(),
                Value<String?> attachmentsJson = const Value.absent(),
                Value<int> msgType = const Value.absent(),
                Value<String?> extraJson = const Value.absent(),
                Value<String?> codeLang = const Value.absent(),
                Value<String?> codeText = const Value.absent(),
                Value<String?> locationLatitude = const Value.absent(),
                Value<String?> locationLongitude = const Value.absent(),
                Value<String?> locationDescription = const Value.absent(),
                Value<String?> replyMarkupJson = const Value.absent(),
                Value<String?> pollJson = const Value.absent(),
              }) => CachedMessagesCompanion(
                id: id,
                isGroupChat: isGroupChat,
                peerUserId: peerUserId,
                peerGroupId: peerGroupId,
                fromPeerUserId: fromPeerUserId,
                content: content,
                createdAt: createdAt,
                isRead: isRead,
                replyToMessageId: replyToMessageId,
                forwarded: forwarded,
                forwardedFromMessageId: forwardedFromMessageId,
                attachmentsJson: attachmentsJson,
                msgType: msgType,
                extraJson: extraJson,
                codeLang: codeLang,
                codeText: codeText,
                locationLatitude: locationLatitude,
                locationLongitude: locationLongitude,
                locationDescription: locationDescription,
                replyMarkupJson: replyMarkupJson,
                pollJson: pollJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> isGroupChat = const Value.absent(),
                required int peerUserId,
                Value<int> peerGroupId = const Value.absent(),
                required int fromPeerUserId,
                required String content,
                required int createdAt,
                Value<bool> isRead = const Value.absent(),
                Value<int> replyToMessageId = const Value.absent(),
                Value<bool> forwarded = const Value.absent(),
                Value<int> forwardedFromMessageId = const Value.absent(),
                Value<String?> attachmentsJson = const Value.absent(),
                Value<int> msgType = const Value.absent(),
                Value<String?> extraJson = const Value.absent(),
                Value<String?> codeLang = const Value.absent(),
                Value<String?> codeText = const Value.absent(),
                Value<String?> locationLatitude = const Value.absent(),
                Value<String?> locationLongitude = const Value.absent(),
                Value<String?> locationDescription = const Value.absent(),
                Value<String?> replyMarkupJson = const Value.absent(),
                Value<String?> pollJson = const Value.absent(),
              }) => CachedMessagesCompanion.insert(
                id: id,
                isGroupChat: isGroupChat,
                peerUserId: peerUserId,
                peerGroupId: peerGroupId,
                fromPeerUserId: fromPeerUserId,
                content: content,
                createdAt: createdAt,
                isRead: isRead,
                replyToMessageId: replyToMessageId,
                forwarded: forwarded,
                forwardedFromMessageId: forwardedFromMessageId,
                attachmentsJson: attachmentsJson,
                msgType: msgType,
                extraJson: extraJson,
                codeLang: codeLang,
                codeText: codeText,
                locationLatitude: locationLatitude,
                locationLongitude: locationLongitude,
                locationDescription: locationDescription,
                replyMarkupJson: replyMarkupJson,
                pollJson: pollJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedMessagesTable,
      CachedMessage,
      $$CachedMessagesTableFilterComposer,
      $$CachedMessagesTableOrderingComposer,
      $$CachedMessagesTableAnnotationComposer,
      $$CachedMessagesTableCreateCompanionBuilder,
      $$CachedMessagesTableUpdateCompanionBuilder,
      (
        CachedMessage,
        BaseReferences<_$AppDatabase, $CachedMessagesTable, CachedMessage>,
      ),
      CachedMessage,
      PrefetchHooks Function()
    >;
typedef $$CachedChatsTableCreateCompanionBuilder =
    CachedChatsCompanion Function({
      Value<int> id,
      Value<bool> isGroup,
      required int peerUserId,
      Value<int> peerGroupId,
      required String title,
      Value<String> userUsername,
      Value<String> userName,
      Value<String> userSurname,
      required int updatedAt,
      Value<int> unreadCount,
      Value<int> memberCount,
      Value<String?> photoId,
      Value<String?> lastMessagePreview,
      Value<bool> notificationsMuted,
      Value<int> listId,
      Value<bool> isPinned,
    });
typedef $$CachedChatsTableUpdateCompanionBuilder =
    CachedChatsCompanion Function({
      Value<int> id,
      Value<bool> isGroup,
      Value<int> peerUserId,
      Value<int> peerGroupId,
      Value<String> title,
      Value<String> userUsername,
      Value<String> userName,
      Value<String> userSurname,
      Value<int> updatedAt,
      Value<int> unreadCount,
      Value<int> memberCount,
      Value<String?> photoId,
      Value<String?> lastMessagePreview,
      Value<bool> notificationsMuted,
      Value<int> listId,
      Value<bool> isPinned,
    });

class $$CachedChatsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedChatsTable> {
  $$CachedChatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isGroup => $composableBuilder(
    column: $table.isGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get peerGroupId => $composableBuilder(
    column: $table.peerGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userUsername => $composableBuilder(
    column: $table.userUsername,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userSurname => $composableBuilder(
    column: $table.userSurname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoId => $composableBuilder(
    column: $table.photoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationsMuted => $composableBuilder(
    column: $table.notificationsMuted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedChatsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedChatsTable> {
  $$CachedChatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGroup => $composableBuilder(
    column: $table.isGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get peerGroupId => $composableBuilder(
    column: $table.peerGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userUsername => $composableBuilder(
    column: $table.userUsername,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userSurname => $composableBuilder(
    column: $table.userSurname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoId => $composableBuilder(
    column: $table.photoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationsMuted => $composableBuilder(
    column: $table.notificationsMuted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedChatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedChatsTable> {
  $$CachedChatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isGroup =>
      $composableBuilder(column: $table.isGroup, builder: (column) => column);

  GeneratedColumn<int> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get peerGroupId => $composableBuilder(
    column: $table.peerGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get userUsername => $composableBuilder(
    column: $table.userUsername,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<String> get userSurname => $composableBuilder(
    column: $table.userSurname,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoId =>
      $composableBuilder(column: $table.photoId, builder: (column) => column);

  GeneratedColumn<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notificationsMuted => $composableBuilder(
    column: $table.notificationsMuted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);
}

class $$CachedChatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedChatsTable,
          CachedChat,
          $$CachedChatsTableFilterComposer,
          $$CachedChatsTableOrderingComposer,
          $$CachedChatsTableAnnotationComposer,
          $$CachedChatsTableCreateCompanionBuilder,
          $$CachedChatsTableUpdateCompanionBuilder,
          (
            CachedChat,
            BaseReferences<_$AppDatabase, $CachedChatsTable, CachedChat>,
          ),
          CachedChat,
          PrefetchHooks Function()
        > {
  $$CachedChatsTableTableManager(_$AppDatabase db, $CachedChatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedChatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedChatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedChatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> isGroup = const Value.absent(),
                Value<int> peerUserId = const Value.absent(),
                Value<int> peerGroupId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> userUsername = const Value.absent(),
                Value<String> userName = const Value.absent(),
                Value<String> userSurname = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int> memberCount = const Value.absent(),
                Value<String?> photoId = const Value.absent(),
                Value<String?> lastMessagePreview = const Value.absent(),
                Value<bool> notificationsMuted = const Value.absent(),
                Value<int> listId = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
              }) => CachedChatsCompanion(
                id: id,
                isGroup: isGroup,
                peerUserId: peerUserId,
                peerGroupId: peerGroupId,
                title: title,
                userUsername: userUsername,
                userName: userName,
                userSurname: userSurname,
                updatedAt: updatedAt,
                unreadCount: unreadCount,
                memberCount: memberCount,
                photoId: photoId,
                lastMessagePreview: lastMessagePreview,
                notificationsMuted: notificationsMuted,
                listId: listId,
                isPinned: isPinned,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> isGroup = const Value.absent(),
                required int peerUserId,
                Value<int> peerGroupId = const Value.absent(),
                required String title,
                Value<String> userUsername = const Value.absent(),
                Value<String> userName = const Value.absent(),
                Value<String> userSurname = const Value.absent(),
                required int updatedAt,
                Value<int> unreadCount = const Value.absent(),
                Value<int> memberCount = const Value.absent(),
                Value<String?> photoId = const Value.absent(),
                Value<String?> lastMessagePreview = const Value.absent(),
                Value<bool> notificationsMuted = const Value.absent(),
                Value<int> listId = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
              }) => CachedChatsCompanion.insert(
                id: id,
                isGroup: isGroup,
                peerUserId: peerUserId,
                peerGroupId: peerGroupId,
                title: title,
                userUsername: userUsername,
                userName: userName,
                userSurname: userSurname,
                updatedAt: updatedAt,
                unreadCount: unreadCount,
                memberCount: memberCount,
                photoId: photoId,
                lastMessagePreview: lastMessagePreview,
                notificationsMuted: notificationsMuted,
                listId: listId,
                isPinned: isPinned,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedChatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedChatsTable,
      CachedChat,
      $$CachedChatsTableFilterComposer,
      $$CachedChatsTableOrderingComposer,
      $$CachedChatsTableAnnotationComposer,
      $$CachedChatsTableCreateCompanionBuilder,
      $$CachedChatsTableUpdateCompanionBuilder,
      (
        CachedChat,
        BaseReferences<_$AppDatabase, $CachedChatsTable, CachedChat>,
      ),
      CachedChat,
      PrefetchHooks Function()
    >;
typedef $$PendingOutgoingMessagesTableCreateCompanionBuilder =
    PendingOutgoingMessagesCompanion Function({
      required String localId,
      required int peerUserId,
      Value<int> peerGroupId,
      required String content,
      Value<String?> attachmentsJson,
      Value<int> replyToId,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$PendingOutgoingMessagesTableUpdateCompanionBuilder =
    PendingOutgoingMessagesCompanion Function({
      Value<String> localId,
      Value<int> peerUserId,
      Value<int> peerGroupId,
      Value<String> content,
      Value<String?> attachmentsJson,
      Value<int> replyToId,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$PendingOutgoingMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $PendingOutgoingMessagesTable> {
  $$PendingOutgoingMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get peerGroupId => $composableBuilder(
    column: $table.peerGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get replyToId => $composableBuilder(
    column: $table.replyToId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingOutgoingMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingOutgoingMessagesTable> {
  $$PendingOutgoingMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get peerGroupId => $composableBuilder(
    column: $table.peerGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get replyToId => $composableBuilder(
    column: $table.replyToId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingOutgoingMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingOutgoingMessagesTable> {
  $$PendingOutgoingMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<int> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get peerGroupId => $composableBuilder(
    column: $table.peerGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get replyToId =>
      $composableBuilder(column: $table.replyToId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingOutgoingMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingOutgoingMessagesTable,
          PendingOutgoingMessage,
          $$PendingOutgoingMessagesTableFilterComposer,
          $$PendingOutgoingMessagesTableOrderingComposer,
          $$PendingOutgoingMessagesTableAnnotationComposer,
          $$PendingOutgoingMessagesTableCreateCompanionBuilder,
          $$PendingOutgoingMessagesTableUpdateCompanionBuilder,
          (
            PendingOutgoingMessage,
            BaseReferences<
              _$AppDatabase,
              $PendingOutgoingMessagesTable,
              PendingOutgoingMessage
            >,
          ),
          PendingOutgoingMessage,
          PrefetchHooks Function()
        > {
  $$PendingOutgoingMessagesTableTableManager(
    _$AppDatabase db,
    $PendingOutgoingMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingOutgoingMessagesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PendingOutgoingMessagesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingOutgoingMessagesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<int> peerUserId = const Value.absent(),
                Value<int> peerGroupId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> attachmentsJson = const Value.absent(),
                Value<int> replyToId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingOutgoingMessagesCompanion(
                localId: localId,
                peerUserId: peerUserId,
                peerGroupId: peerGroupId,
                content: content,
                attachmentsJson: attachmentsJson,
                replyToId: replyToId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                required int peerUserId,
                Value<int> peerGroupId = const Value.absent(),
                required String content,
                Value<String?> attachmentsJson = const Value.absent(),
                Value<int> replyToId = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingOutgoingMessagesCompanion.insert(
                localId: localId,
                peerUserId: peerUserId,
                peerGroupId: peerGroupId,
                content: content,
                attachmentsJson: attachmentsJson,
                replyToId: replyToId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingOutgoingMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingOutgoingMessagesTable,
      PendingOutgoingMessage,
      $$PendingOutgoingMessagesTableFilterComposer,
      $$PendingOutgoingMessagesTableOrderingComposer,
      $$PendingOutgoingMessagesTableAnnotationComposer,
      $$PendingOutgoingMessagesTableCreateCompanionBuilder,
      $$PendingOutgoingMessagesTableUpdateCompanionBuilder,
      (
        PendingOutgoingMessage,
        BaseReferences<
          _$AppDatabase,
          $PendingOutgoingMessagesTable,
          PendingOutgoingMessage
        >,
      ),
      PendingOutgoingMessage,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SyncStatesTableTableManager get syncStates =>
      $$SyncStatesTableTableManager(_db, _db.syncStates);
  $$CachedMessagesTableTableManager get cachedMessages =>
      $$CachedMessagesTableTableManager(_db, _db.cachedMessages);
  $$CachedChatsTableTableManager get cachedChats =>
      $$CachedChatsTableTableManager(_db, _db.cachedChats);
  $$PendingOutgoingMessagesTableTableManager get pendingOutgoingMessages =>
      $$PendingOutgoingMessagesTableTableManager(
        _db,
        _db.pendingOutgoingMessages,
      );
}
