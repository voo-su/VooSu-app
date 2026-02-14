import 'package:equatable/equatable.dart';

class PendingQueueItem extends Equatable {
  final String localId;
  final String content;
  final String? attachmentsJson;
  final int replyToId;
  final DateTime createdAt;

  const PendingQueueItem({
    required this.localId,
    required this.content,
    this.attachmentsJson,
    this.replyToId = 0,
    required this.createdAt,
  });

  bool get hasAttachments => attachmentsJson != null && attachmentsJson!.isNotEmpty && attachmentsJson != '[]';

  @override
  List<Object?> get props => [
    localId,
    content,
    attachmentsJson,
    replyToId,
    createdAt,
  ];
}
