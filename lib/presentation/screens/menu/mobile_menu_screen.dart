import 'package:flutter/material.dart';

class MobileMenuScreen extends StatelessWidget {
  final VoidCallback onSelectEditor;
  final VoidCallback onLogout;
  final bool showAdmin;
  final VoidCallback? onSelectAdmin;

  const MobileMenuScreen({
    super.key,
    required this.onSelectEditor,
    required this.onLogout,
    this.showAdmin = false,
    this.onSelectAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Меню')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                Icons.edit_note_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Редактор'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onSelectEditor,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: theme.colorScheme.error,
              ),
              title: const Text('Выйти'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onLogout,
            ),
          ),
          if (showAdmin && onSelectAdmin != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Администрирование'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onSelectAdmin,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
