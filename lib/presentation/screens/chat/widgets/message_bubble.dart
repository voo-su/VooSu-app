import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voosu/core/attachment_type_helper.dart';
import 'package:voosu/core/date_formatter.dart';
import 'package:voosu/domain/entities/chat_attachment.dart';
import 'package:voosu/domain/entities/message.dart';
import 'package:voosu/domain/entities/poll.dart';
import 'package:voosu/domain/entities/reply_markup.dart';
import 'package:voosu/presentation/screens/chat/widgets/chat_attachment_view.dart';

String _attachmentTypeLabel(ChatAttachment att) {
  int type = att.type;
  if (type == 0) {
    if (AttachmentType.isImageFilename(att.filename)) {
      return 'Фотография';
    }

    if (AttachmentType.isVideoFilename(att.filename)) {
      return 'Видео';
    }

    if (AttachmentType.isAudioFilename(att.filename)) {
      return 'Аудио';
    }

    return 'Документ';
  }

  switch (type) {
    case AttachmentType.image:
      return 'Фотография';
    case AttachmentType.video:
      return 'Видео';
    case AttachmentType.audio:
      return 'Аудио';
    case AttachmentType.document:
    default:
      return 'Документ';
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isFromMe;
  final Message? replyToMessage;
  final String? replyToSenderName;
  final String? forwardedSenderName;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final Future<void> Function(int fileId, String filename)?
  onDownloadAttachment;
  final Future<List<int>?> Function(int fileId)? onLoadAttachmentContent;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onToggleSelection;
  final void Function(int messageId, String callbackData)? onInlineButtonPressed;
  final void Function(int messageId, int optionId)? onVotePoll;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromMe,
    this.replyToMessage,
    this.replyToSenderName,
    this.forwardedSenderName,
    this.onDelete,
    this.onReply,
    this.onForward,
    this.onDownloadAttachment,
    this.onLoadAttachmentContent,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onToggleSelection,
    this.onInlineButtonPressed,
    this.onVotePoll,
  });

  static const double _bubbleRadius = 18;
  static const double _tailRadius = 4;
  static const double _maxWidthFraction = 0.75;
  static const double _maxWidthFractionNarrow = 0.52;

  static void _showContextMenu(
    BuildContext context,
    Offset? globalPosition,
    String? copyableText,
    VoidCallback? onDelete,
    VoidCallback? onReply,
    VoidCallback? onForward,
    VoidCallback? onToggleSelection,
  ) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || (!box.hasSize)) {
      return;
    }

    final position =
        globalPosition ?? box.localToGlobal(box.size.bottomCenter(Offset.zero));
    final menuRect = RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx + 1,
      position.dy + 1,
    );

    final items = <PopupMenuEntry<String>>[];
    if (copyableText != null && copyableText.trim().isNotEmpty) {
      items.add(
        const PopupMenuItem<String>(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy_rounded, size: 20),
              SizedBox(width: 8),
              Text('Копировать'),
            ],
          ),
        ),
      );
    }
    if (onReply != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'reply',
          child: Row(
            children: [
              Icon(Icons.reply_rounded, size: 20),
              SizedBox(width: 8),
              Text('Ответить'),
            ],
          ),
        ),
      );
    }
    if (onForward != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'forward',
          child: Row(
            children: [
              Icon(Icons.forward_rounded, size: 20),
              SizedBox(width: 8),
              Text('Переслать'),
            ],
          ),
        ),
      );
    }
    if (onDelete != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20),
              SizedBox(width: 8),
              Text('Удалить'),
            ],
          ),
        ),
      );
    }
    if (onToggleSelection != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'select',
          child: Row(
            children: [
              Icon(Icons.check_box_outlined, size: 20),
              SizedBox(width: 8),
              Text('Выделить'),
            ],
          ),
        ),
      );
    }
    if (items.isEmpty) return;

    showMenu<String>(context: context, position: menuRect, items: items).then((
      value,
    ) async {
      if (value == 'copy' &&
          copyableText != null &&
          copyableText.trim().isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: copyableText));
      }
      if (value == 'reply') {
        onReply?.call();
      }

      if (value == 'forward') {
        onForward?.call();
      }

      if (value == 'delete') {
        onDelete?.call();
      }

      if (value == 'select') {
        onToggleSelection?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = ChatMessageTime.format(message.createdAt);
    final isDark = theme.brightness == Brightness.dark;

    final sentBubbleColor = isDark
        ? const Color(0xFF2E6B9E)
        : theme.colorScheme.primary;
    final receivedBubbleColor = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.surfaceContainerHighest;
    final sentTextColor = theme.colorScheme.onPrimary;
    final receivedTextColor = theme.colorScheme.onSurface;
    final timeColor = isFromMe
        ? sentTextColor.withValues(alpha: 0.85)
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.9);

    final bubbleColor = isFromMe ? sentBubbleColor : receivedBubbleColor;
    final textColor = isFromMe ? sentTextColor : receivedTextColor;

    final showCheckbox = isSelectionMode && isFromMe;
    final onBubbleTap = showCheckbox && onToggleSelection != null
        ? onToggleSelection
        : null;
    final showContextMenu =
        !isSelectionMode &&
        (onReply != null ||
            onForward != null ||
            onDelete != null ||
            onToggleSelection != null);

    final useNarrowWidth =
        replyToMessage != null ||
        (message.attachments.isNotEmpty &&
            message.attachments.every((a) => a.type == AttachmentType.audio));
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBubbleWidth =
            constraints.maxWidth *
            (useNarrowWidth ? _maxWidthFractionNarrow : _maxWidthFraction);
        Widget row = Row(
          mainAxisAlignment: isFromMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showCheckbox)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Checkbox(
                  value: isSelected,
                  onChanged: onToggleSelection != null
                      ? (_) => onToggleSelection!()
                      : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            Flexible(
              child: GestureDetector(
                onTap: onBubbleTap,
                onLongPress: showContextMenu
                    ? () => _showContextMenu(
                        context,
                        null,
                        message.content,
                        onDelete,
                        onReply,
                        onForward,
                        onToggleSelection,
                      )
                    : (isFromMe && onToggleSelection != null
                          ? onToggleSelection
                          : null),
                onSecondaryTapDown: showContextMenu
                    ? (details) => _showContextMenu(
                        context,
                        details.globalPosition,
                        message.content,
                        onDelete,
                        onReply,
                        onForward,
                        onToggleSelection,
                      )
                    : null,
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  padding: const EdgeInsets.fromLTRB(12, 8, 10, 6),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(_bubbleRadius),
                      topRight: const Radius.circular(_bubbleRadius),
                      bottomLeft: Radius.circular(
                        isFromMe ? _bubbleRadius : _tailRadius,
                      ),
                      bottomRight: Radius.circular(
                        isFromMe ? _tailRadius : _bubbleRadius,
                      ),
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
                      if (message.forwarded) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.forward_rounded,
                                size: 14,
                                color: textColor.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Переслано',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: textColor.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (forwardedSenderName != null &&
                                  forwardedSenderName!.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Text(
                                  'от $forwardedSenderName',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: textColor.withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                              if (message.forwardedFromMessageDeleted) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(удалённое сообщение)',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: textColor.withValues(alpha: 0.6),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (message.replyToMessageId > 0) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: textColor.withValues(alpha: 0.6),
                                width: 3,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Ответ на сообщение',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: textColor.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (replyToMessage != null &&
                                    replyToSenderName != null &&
                                    replyToSenderName!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'от $replyToSenderName',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: textColor.withValues(alpha: 0.75),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 2),
                                if (replyToMessage != null)
                                  SelectableText(
                                    replyToMessage!.content,
                                    maxLines: 2,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: textColor.withValues(alpha: 0.9),
                                      fontSize: 13,
                                    ),
                                  )
                                else
                                  Text(
                                    'Удалённое сообщение',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: textColor.withValues(alpha: 0.6),
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                if (replyToMessage != null &&
                                    replyToMessage!.attachments.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: replyToMessage!.attachments.map((
                                      att,
                                    ) {
                                      return _AttachmentPreviewTile(
                                        attachment: att,
                                        textColor: textColor,
                                        onLoadContent: onLoadAttachmentContent,
                                        typeLabel: _attachmentTypeLabel(att),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (message.attachments.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ...message.attachments.map(
                          (att) => ChatAttachmentView(
                            attachment: att,
                            onLoadContent: onLoadAttachmentContent != null
                              ? (fileId) => onLoadAttachmentContent!(fileId)
                              : (_) async => null,
                            onDownload: onDownloadAttachment,
                            textColor: textColor,
                          ),
                        ),
                      ],
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (message.content.trim().isNotEmpty)
                            Flexible(
                              child: SelectableText(
                                message.content,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: textColor,
                                  height: 1.35,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          if (message.content.trim().isNotEmpty)
                            const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                timeStr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: timeColor,
                                  height: 1.2,
                                ),
                              ),
                              if (isFromMe) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  message.isRead ? Icons.done_all : Icons.done,
                                  size: 16,
                                  color: timeColor.withValues(alpha: 0.95),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      if (message.poll != null) ...[
                        const SizedBox(height: 8),
                        _PollWidget(
                          poll: message.poll!,
                          messageId: message.id,
                          textColor: textColor,
                          onVote: onVotePoll,
                        ),
                      ],
                      if (message.replyMarkup != null && message.replyMarkup!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _InlineKeyboardWidget(
                          replyMarkup: message.replyMarkup!,
                          messageId: message.id,
                          onButtonPressed: onInlineButtonPressed,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: row,
        );
      },
    );
  }
}

class _AttachmentPreviewTile extends StatefulWidget {
  final ChatAttachment attachment;
  final Color textColor;
  final Future<List<int>?> Function(int fileId)? onLoadContent;
  final String? typeLabel;

  const _AttachmentPreviewTile({
    required this.attachment,
    required this.textColor,
    this.onLoadContent,
    this.typeLabel,
  });

  @override
  State<_AttachmentPreviewTile> createState() => _AttachmentPreviewTileState();
}

class _AttachmentPreviewTileState extends State<_AttachmentPreviewTile> {
  List<int>? _bytes;

  static const double _size = 52;

  @override
  void initState() {
    super.initState();
    if (widget.onLoadContent != null &&  widget.attachment.type == AttachmentType.image) {
      widget.onLoadContent!(widget.attachment.fileId).then((bytes) {
        if (mounted) {
          setState(() {
            _bytes = bytes;
          });
        }
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage = widget.attachment.type == AttachmentType.image;
    final showThumbnail = isImage && _bytes != null && _bytes!.isNotEmpty;

    final tile = showThumbnail
        ? ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(
              Uint8List.fromList(_bytes!),
              fit: BoxFit.cover,
              width: _size,
              height: _size,
              errorBuilder: (_, _, _) => _buildIconTile(),
            ),
          )
        : _buildIconTile();

    if (widget.typeLabel == null || widget.typeLabel!.isEmpty) {
      return tile;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        tile,
        const SizedBox(height: 4),
        Text(
          widget.typeLabel!,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: widget.textColor.withValues(alpha: 0.85),
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildIconTile() {
    IconData icon;
    switch (widget.attachment.type) {
      case AttachmentType.video:
        icon = Icons.videocam_rounded;
        break;
      case AttachmentType.audio:
        icon = Icons.audiotrack_rounded;
        break;
      default:
        icon = Icons.attach_file_rounded;
    }

    return Tooltip(
      message: widget.attachment.filename,
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: widget.textColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 24,
          color: widget.textColor.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _PollWidget extends StatelessWidget {
  final Poll poll;
  final int messageId;
  final Color textColor;
  final void Function(int messageId, int optionId)? onVote;

  const _PollWidget({
    required this.poll,
    required this.messageId,
    required this.textColor,
    this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalVotes = poll.options.fold<int>(0, (s, o) => s + o.voteCount);
    final isDark = theme.brightness == Brightness.dark;
    final optionBg = isDark
      ? textColor.withValues(alpha: 0.08)
      : textColor.withValues(alpha: 0.06);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...poll.options.map((opt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: optionBg,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onVote != null
                    ? () => onVote!(messageId, opt.optionId)
                    : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            opt.text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          opt.voteCount > 0 ? '${opt.voteCount}' : '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: textColor.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          if (poll.anonymous && totalVotes > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Анонимный опрос',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            )
          else if (!poll.anonymous && totalVotes > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Всего голосов: $totalVotes',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InlineKeyboardWidget extends StatelessWidget {
  final ReplyMarkup replyMarkup;
  final int messageId;
  final void Function(int messageId, String callbackData)? onButtonPressed;

  const _InlineKeyboardWidget({
    required this.replyMarkup,
    required this.messageId,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark
      ? theme.colorScheme.primary.withValues(alpha: 0.85)
      : theme.colorScheme.primary;
    final bgColor = isDark
      ? color.withValues(alpha: 0.15)
      : color.withValues(alpha: 0.12);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: replyMarkup.inlineKeyboard.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: row.buttons.map((btn) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Material(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: onButtonPressed != null
                      ? () => onButtonPressed!(messageId, btn.callbackData)
                      : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        btn.text,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
