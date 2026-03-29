import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:voosu/core/chat_msg_type.dart';
import 'package:voosu/core/date_formatter.dart';
import 'package:voosu/domain/entities/message.dart';

class SystemChatMessageRow extends StatelessWidget {
  const SystemChatMessageRow({
    super.key,
    required this.message,
    this.onUserTap,
  });

  final Message message;
  final ValueChanged<int>? onUserTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = ChatMessageTime.format(message.createdAt);
    final muted = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75);
    final linkStyle = TextStyle(
      color: theme.colorScheme.primary,
      fontSize: 13,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
    );
    final bodyStyle = theme.textTheme.bodySmall?.copyWith(
      color: muted,
      fontSize: 13,
      fontWeight: FontWeight.w300,
    );

    final extra = _parseExtra(message.extraJson);
    final body = _buildBody(extra, bodyStyle, linkStyle);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            body,
            const SizedBox(height: 2),
            Text(
              timeStr,
              style: theme.textTheme.labelSmall?.copyWith(
                color: muted.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    Map<String, dynamic>? extra,
    TextStyle? bodyStyle,
    TextStyle linkStyle,
  ) {
    final onTap = onUserTap;

    Widget userLink(int id, String label) {
      final text = label.isNotEmpty ? label : '#$id';
      if (id <= 0 || onTap == null) {
        return Text(text, style: bodyStyle, textAlign: TextAlign.center);
      }
      return GestureDetector(
        onTap: () => onTap(id),
        child: Text(text, style: linkStyle, textAlign: TextAlign.center),
      );
    }

    Widget sep(String s) => Text(s, style: bodyStyle, textAlign: TextAlign.center);

    List<Widget> memberList(List<({int id, String name})> members) {
      if (members.isEmpty) {
        return [sep('')];
      }
      final out = <Widget>[];
      for (var i = 0; i < members.length; i++) {
        if (i > 0) {
          out.add(sep(', '));
        }
        final m = members[i];
        out.add(userLink(m.id, m.name));
      }
      return out;
    }

    switch (message.msgType) {
      case ChatMsgType.sysText:
        return _SysTextPill(text: message.content.trim().isEmpty ? 'Системное сообщение' : message.content);
      case ChatMsgType.sysGroupCreate:
      case ChatMsgType.sysGroupMemberJoin:
        if (extra == null) {
          return _fallback(message.content, bodyStyle);
        }
        final ownerId = _asInt(extra['owner_id']);
        final ownerName = _asString(extra['owner_name']);
        final members = _parseMembers(extra['members']);
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 0,
          children: [
            userLink(ownerId, ownerName),
            sep(' пригласил(а) '),
            ...memberList(members),
            sep(' в чат'),
          ],
        );
      case ChatMsgType.sysGroupMemberQuit:
        if (extra == null) {
          return _fallback(message.content, bodyStyle);
        }
        final ownerId = _asInt(extra['owner_id']);
        final ownerName = _asString(extra['owner_name']);
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            userLink(ownerId, ownerName),
            sep(' покинул(а) чат'),
          ],
        );
      case ChatMsgType.sysGroupMemberKicked:
        if (extra == null) {
          return _fallback(message.content, bodyStyle);
        }
        final ownerId = _asInt(extra['owner_id']);
        final ownerName = _asString(extra['owner_name']);
        final members = _parseMembers(extra['members']);
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            userLink(ownerId, ownerName),
            sep(' исключил(а) '),
            ...memberList(members),
          ],
        );
      case ChatMsgType.sysGroupMuted:
        if (extra == null) {
          return _fallback(message.content, bodyStyle);
        }
        final ownerId = _asInt(extra['owner_id']);
        final ownerName = _asString(extra['owner_name']);
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            userLink(ownerId, ownerName),
            sep(' отключил(а) уведомления для всех'),
          ],
        );
      case ChatMsgType.sysGroupCancelMuted:
        if (extra == null) {
          return _fallback(message.content, bodyStyle);
        }
        final ownerId = _asInt(extra['owner_id']);
        final ownerName = _asString(extra['owner_name']);
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            userLink(ownerId, ownerName),
            sep(' снова включил(а) уведомления для всех'),
          ],
        );
      case ChatMsgType.sysGroupMemberMuted:
        if (extra == null) {
          return _fallback(message.content, bodyStyle);
        }
        final ownerId = _asInt(extra['owner_id']);
        final ownerName = _asString(extra['owner_name']);
        final members = _parseMembers(extra['members']);
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            userLink(ownerId, ownerName),
            sep(' ограничил(а) уведомления: '),
            ...memberList(members),
          ],
        );
      case ChatMsgType.sysGroupMemberCancelMuted:
        if (extra == null) {
          return _fallback(message.content, bodyStyle);
        }
        final ownerId = _asInt(extra['owner_id']);
        final ownerName = _asString(extra['owner_name']);
        final members = _parseMembers(extra['members']);
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            userLink(ownerId, ownerName),
            sep(' снял(а) ограничения уведомлений: '),
            ...memberList(members),
          ],
        );
      case ChatMsgType.sysGroupDismissed:
        if (extra == null) {
          return _fallback(message.content, bodyStyle);
        }
        final ownerId = _asInt(extra['owner_id']);
        final ownerName = _asString(extra['owner_name']);
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            userLink(ownerId, ownerName),
            sep(' удалил(а) группу'),
          ],
        );
      case ChatMsgType.sysGroupTransfer:
        if (extra == null) {
          return _fallback(message.content, bodyStyle);
        }
        final oldId = _asInt(extra['old_owner_id']);
        final oldName = _asString(extra['old_owner_name']);
        final newId = _asInt(extra['new_owner_id']);
        final newName = _asString(extra['new_owner_name']);
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            userLink(oldId, oldName),
            sep(' передал(а) права владельца '),
            userLink(newId, newName),
          ],
        );
      case ChatMsgType.sysGroupMessageRevoke:
        if (extra == null) {
          return _fallback(message.content, bodyStyle);
        }
        final ownerId = _asInt(extra['owner_id']);
        final ownerName = _asString(extra['owner_name']);
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            userLink(ownerId, ownerName),
            sep(' удалил(а) сообщение'),
          ],
        );
      default:
        return _fallback(
          message.content.trim().isNotEmpty ? message.content : 'Системное сообщение',
          bodyStyle,
        );
    }
  }

  static Widget _fallback(String text, TextStyle? bodyStyle) {
    return Text(
      text.isNotEmpty ? text : 'Системное сообщение',
      textAlign: TextAlign.center,
      style: bodyStyle,
    );
  }
}

class _SysTextPill extends StatelessWidget {
  const _SysTextPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.dividerColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w300,
          height: 1.25,
        ),
      ),
    );
  }
}

Map<String, dynamic>? _parseExtra(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  try {
    final d = jsonDecode(raw);
    if (d is Map<String, dynamic>) {
      return d;
    }
    if (d is Map) {
      return d.map((k, v) => MapEntry(k.toString(), v));
    }
  } catch (_) {}
  return null;
}

int _asInt(dynamic v) {
  if (v is int) {
    return v;
  }
  if (v is num) {
    return v.toInt();
  }
  return 0;
}

String _asString(dynamic v) {
  if (v is String) {
    return v;
  }
  if (v == null) {
    return '';
  }
  return v.toString();
}

List<({int id, String name})> _parseMembers(dynamic raw) {
  if (raw is! List) {
    return [];
  }
  final out = <({int id, String name})>[];
  for (final e in raw) {
    if (e is! Map) {
      continue;
    }
    final m = Map<String, dynamic>.from(e);
    final id = _asInt(m['user_id']);
    var name = _asString(m['username']);
    if (name.isEmpty && id > 0) {
      name = '#$id';
    }
    if (id > 0 || name.isNotEmpty) {
      out.add((id: id, name: name));
    }
  }
  return out;
}
