import 'package:voosu/domain/repositories/chat_repository.dart';

class SavePendingMessageUseCase {
  final ChatRepository repo;

  SavePendingMessageUseCase(this.repo);

  Future<void> call({
    required String localId,
    required int peerUserId,
    required String content,
    String? attachmentsJson,
  }) => repo.savePendingMessage(
    localId: localId,
    peerUserId: peerUserId,
    content: content,
    attachmentsJson: attachmentsJson,
  );
}
