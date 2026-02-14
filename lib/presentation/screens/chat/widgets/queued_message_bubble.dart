import 'package:flutter/material.dart';
import 'package:voosu/core/date_formatter.dart';
import 'package:voosu/domain/entities/pending_queue_item.dart';

class QueuedMessageBubble extends StatelessWidget {
  final PendingQueueItem item;
  final Color bubbleColor;
  final Color textColor;
  final Color timeColor;
  final VoidCallback onCancel;

  const QueuedMessageBubble({
    super.key,
    required this.item,
    required this.bubbleColor,
    required this.textColor,
    required this.timeColor,
    required this.onCancel,
  });

  static const double _bubbleRadius = 18;
  static const double _tailRadius = 4;
  static const double _maxWidthFraction = 0.75;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = ChatMessageTime.format(item.createdAt);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBubbleWidth = constraints.maxWidth * _maxWidthFraction;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  padding: const EdgeInsets.fromLTRB(12, 8, 10, 6),
                  decoration: BoxDecoration(
                    color: bubbleColor.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(_bubbleRadius),
                      topRight: const Radius.circular(_bubbleRadius),
                      bottomLeft: Radius.circular(_tailRadius),
                      bottomRight: const Radius.circular(_bubbleRadius),
                    ),
                    border: Border.all(
                      color: bubbleColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: timeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'В очереди',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: timeColor,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (item.content.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: SelectableText(
                            item.content,
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
              const SizedBox(width: 4),
              Material(
                color: Colors.transparent,
                child: IconButton(
                  onPressed: onCancel,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Отменить отправку',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
