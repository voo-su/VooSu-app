import 'package:flutter/material.dart';

Future<bool?> showDeleteScopeDialog(BuildContext context, {bool isFromMe = true}) async {
  final theme = Theme.of(context);
  return showModalBottomSheet<bool>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Удалить сообщение?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_off_outlined),
              title: const Text('Удалить у меня'),
              subtitle: Text(
                isFromMe
                  ? 'Сообщение исчезнет только у вас'
                  : 'Сообщение исчезнет только у вас в этом чате',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () => Navigator.of(context).pop(false),
            ),
            if (isFromMe)
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined),
                title: const Text('Удалить у всех'),
                subtitle: Text(
                  'Сообщение исчезнет у всех участников чата',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(true),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
