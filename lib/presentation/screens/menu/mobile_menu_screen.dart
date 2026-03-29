import 'package:flutter/material.dart';

class MobileMenuScreen extends StatelessWidget {
  final VoidCallback onSelectProfile;
  final VoidCallback? onSelectSearchGroups;
  final VoidCallback? onSelectUserSearch;
  final bool showAdmin;
  final VoidCallback? onSelectAdmin;

  const MobileMenuScreen({
    super.key,
    required this.onSelectProfile,
    this.onSelectSearchGroups,
    this.onSelectUserSearch,
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
                Icons.person_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Профиль'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onSelectProfile,
            ),
          ),
          if (onSelectSearchGroups != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.groups_rounded,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Поиск групп'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onSelectSearchGroups,
              ),
            ),
          ],
          if (onSelectUserSearch != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.person_search_rounded,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Поиск пользователей'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onSelectUserSearch,
              ),
            ),
          ],
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
