import 'package:voosu/domain/entities/chat.dart';
import 'package:voosu/domain/repositories/chat_repository.dart';

class ReportInlineCallbackUseCase {
  final ChatRepository _repo;

  ReportInlineCallbackUseCase(this._repo);

  Future<void> call({
    required Chat chat,
    required int messageId,
    required String callbackData,
  }) => _repo.reportInlineCallback(
    chat: chat,
    messageId: messageId,
    callbackData: callbackData,
  );
}
