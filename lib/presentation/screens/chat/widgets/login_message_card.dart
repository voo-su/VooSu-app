import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:voosu/core/date_formatter.dart';
import 'package:voosu/domain/entities/message.dart';

class LoginMessageCard extends StatelessWidget {
  final Message message;

  const LoginMessageCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String ip = '';
    String agent = '';
    String address = '';
    String datetimeRaw = '';

    final raw = message.extraJson;
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        ip = (m['ip'] as String?)?.trim() ?? '';
        agent = (m['agent'] as String?)?.trim() ?? '';
        address = (m['address'] as String?)?.trim() ?? '';
        datetimeRaw = (m['datetime'] as String?)?.trim() ?? '';
      } catch (_) {}
    }

    String timeLabel = '';
    if (datetimeRaw.isNotEmpty) {
      final parsed = DateTime.tryParse(datetimeRaw);
      timeLabel = parsed != null
          ? ChatMessageTime.format(parsed)
          : datetimeRaw;
    }

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Вход в аккаунт',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                if (agent.isNotEmpty)
                  _line(theme, 'Устройство', agent),
                if (ip.isNotEmpty) _line(theme, 'IP', ip),
                if (address.isNotEmpty)
                  _line(theme, 'Локация', address),
                if (timeLabel.isNotEmpty)
                  _line(theme, 'Время', timeLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _line(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          style: theme.textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
