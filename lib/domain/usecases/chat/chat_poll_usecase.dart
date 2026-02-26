import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class ChatPollUseCase {
  final ChatRepository _repo;

  ChatPollUseCase(this._repo);

  Future<Message> createPoll({
    required int groupId,
    required String question,
    required List<String> options,
    required bool anonymous,
  }) =>
      _repo.createPoll(
        groupId: groupId,
        question: question,
        options: options,
        anonymous: anonymous,
      );

  Future<void> votePoll({
    required int groupId,
    required int messageId,
    required int optionId,
  }) =>
      _repo.votePoll(
        groupId: groupId,
        messageId: messageId,
        optionId: optionId,
      );
}
