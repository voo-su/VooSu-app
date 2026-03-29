import 'package:voosu/domain/entities/chat_mention_member.dart';

class GroupMessageMention {
  final int all;
  final List<int> uids;

  const GroupMessageMention({this.all = 0, this.uids = const []});

  bool get isEmpty => all == 0 && uids.isEmpty;
}

GroupMessageMention? extractGroupMessageMention(
  String text,
  List<ChatMentionMember> members,
) {
  if (members.isEmpty) {
    return null;
  }
  var hasAll = false;
  final uids = <int>{};
  final byUser = <String, int>{};
  for (final m in members) {
    if (m.userId == 0) {
      continue;
    }
    byUser[m.username.toLowerCase()] = m.userId;
  }
  final re = RegExp(r'@(\w+)');
  for (final m in re.allMatches(text)) {
    final token = m.group(1)!.toLowerCase();
    if (token == 'all') {
      hasAll = true;
      continue;
    }
    final id = byUser[token];
    if (id != null) {
      uids.add(id);
    }
  }
  if (!hasAll && uids.isEmpty) {
    return null;
  }
  final sorted = uids.toList()..sort();
  return GroupMessageMention(all: hasAll ? 1 : 0, uids: sorted);
}
