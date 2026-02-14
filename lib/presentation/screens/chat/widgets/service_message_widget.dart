import 'package:flutter/material.dart';
import 'package:voosu/core/date_formatter.dart';
import 'package:voosu/domain/entities/message.dart';

class ServiceMessageWidget extends StatelessWidget {
  final Message message;

  const ServiceMessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = ChatMessageTime.format(message.createdAt);
    final color = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              timeStr,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
