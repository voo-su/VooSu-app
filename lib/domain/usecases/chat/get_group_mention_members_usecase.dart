import 'package:voosu/domain/entities/chat_mention_member.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class GetGroupMentionMembersUseCase {
  GetGroupMentionMembersUseCase(this._repo);

  final ChatRepository _repo;

  Future<List<ChatMentionMember>> call(int groupId) async {
    if (groupId <= 0) {
      return const [];
    }

    final info = await _repo.getGroupInfo(groupId);
    final out = <ChatMentionMember>[ChatMentionMember.all];
    for (final m in info.members) {
      final u = info.userById[m.userId];
      if (u == null) {
        continue;
      }

      final un = u.username.trim();
      if (un.isEmpty) {
        continue;
      }

      out.add(ChatMentionMember(
        userId: m.userId,
        username: un,
        displayLabel: u.displayName,
      ));
    }
    return out;
  }
}
