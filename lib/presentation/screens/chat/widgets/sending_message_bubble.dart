import 'package:flutter/material.dart';
import 'package:voosu/core/attachment_type_helper.dart';
import 'package:voosu/core/date_formatter.dart';
import 'package:voosu/presentation/screens/chat/bloc/pending_outgoing_message.dart';

class SendingMessageBubble extends StatelessWidget {
  final PendingOutgoingMessage pending;
  final Color bubbleColor;
  final Color textColor;
  final Color timeColor;

  const SendingMessageBubble({
    super.key,
    required this.pending,
    required this.bubbleColor,
    required this.textColor,
    required this.timeColor,
  });

  static const double _bubbleRadius = 18;
  static const double _tailRadius = 4;
  static const double _maxWidthFraction = 0.75;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = ChatMessageTime.format(DateTime.now());

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBubbleWidth = constraints.maxWidth * _maxWidthFraction;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  padding: const EdgeInsets.fromLTRB(12, 8, 10, 6),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(_bubbleRadius),
                      topRight: const Radius.circular(_bubbleRadius),
                      bottomLeft: Radius.circular(_tailRadius),
                      bottomRight: const Radius.circular(_bubbleRadius),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (pending.attachments.isNotEmpty) ...[
                        ...pending.attachments.map(
                          (a) => _buildAttachmentRow(theme, a),
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (pending.text.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            pending.text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              height: 1.35,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (pending.isSubmitting)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: timeColor,
                                ),
                              ),
                            )
                          else if (pending.attachments.any(
                            (a) => a.isUploading,
                          ))
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: timeColor,
                                ),
                              ),
                            ),
                          Text(
                            pending.isSubmitting
                                ? 'Отправка...'
                                : 'Загрузка...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: timeColor,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timeStr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: timeColor,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentRow(ThemeData theme, PendingAttachment a) {
    final isImage = AttachmentType.isImageFilename(a.filename);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isImage ? Icons.image_rounded : _iconForFilename(a.filename),
                  size: 20,
                  color: textColor.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        a.filename,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor.withValues(alpha: 0.95),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (a.isUploading) ...[
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: a.progress,
                          backgroundColor: textColor.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(textColor),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForFilename(String name) {
    if (AttachmentType.isVideoFilename(name)) {
      return Icons.videocam_rounded;
    }

    if (AttachmentType.isAudioFilename(name)) {
      return Icons.audiotrack_rounded;
    }

    return Icons.insert_drive_file_rounded;
  }
}
