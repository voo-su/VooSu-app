import 'package:equatable/equatable.dart';

class PendingAttachment extends Equatable {
  final String filename;
  final int size;
  final double progress;
  final int? fileId;

  const PendingAttachment({
    required this.filename,
    required this.size,
    this.progress = 0,
    this.fileId,
  });

  PendingAttachment copyWith({
    String? filename,
    int? size,
    double? progress,
    int? fileId,
  }) {
    return PendingAttachment(
      filename: filename ?? this.filename,
      size: size ?? this.size,
      progress: progress ?? this.progress,
      fileId: fileId ?? this.fileId,
    );
  }

  bool get isUploading => progress < 1.0 && fileId == null;

  bool get isReady => fileId != null && fileId! != 0;

  @override
  List<Object?> get props => [filename, size, progress, fileId];
}

class PendingOutgoingMessage extends Equatable {
  final String clientId;
  final String text;
  final List<PendingAttachment> attachments;
  final bool isSubmitting;

  const PendingOutgoingMessage({
    required this.clientId,
    required this.text,
    this.attachments = const [],
    this.isSubmitting = false,
  });

  PendingOutgoingMessage copyWith({
    String? clientId,
    String? text,
    List<PendingAttachment>? attachments,
    bool? isSubmitting,
  }) {
    return PendingOutgoingMessage(
      clientId: clientId ?? this.clientId,
      text: text ?? this.text,
      attachments: attachments ?? this.attachments,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  bool get allAttachmentsReady => attachments.every((a) => a.isReady);

  bool get hasAttachments => attachments.isNotEmpty;

  @override
  List<Object?> get props => [
    clientId,
    text,
    attachments,
    isSubmitting,
  ];
}
