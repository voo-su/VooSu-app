import 'package:flutter/material.dart';
import 'package:voosu/core/attachment_type_helper.dart';
import 'package:voosu/domain/entities/chat_attachment.dart';

class ChatAttachmentView extends StatelessWidget {
  final ChatAttachment attachment;
  final Future<void> Function(int fileId, String filename)? onDownload;
  final Color textColor;

  const ChatAttachmentView({
    super.key,
    required this.attachment,
    this.onDownload,
    required this.textColor,
  });

  IconData get _icon {
    switch (attachment.type) {
      case AttachmentType.image:
        return Icons.image_outlined;
      case AttachmentType.video:
        return Icons.videocam_rounded;
      case AttachmentType.audio:
        return Icons.audiotrack_rounded;
      case AttachmentType.document:
      case AttachmentType.unknown:
      default:
        return Icons.attach_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = attachment.filename.isNotEmpty ? attachment.filename : 'Вложение';
    final onTap = onDownload != null
        ? () => onDownload!(attachment.fileId, attachment.filename)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _icon,
                size: 20,
                color: textColor.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: 0.9),
                    decoration: onTap != null ? TextDecoration.underline : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
