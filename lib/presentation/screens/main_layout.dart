import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voosu/core/layout/responsive.dart';
import 'package:voosu/core/router/app_router.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_event.dart';
import 'package:voosu/presentation/screens/chat/chat_screen.dart';
import 'package:voosu/presentation/screens/menu/mobile_menu_screen.dart';
import 'package:voosu/presentation/screens/projects/projects_screen.dart';
import 'package:voosu/presentation/widgets/app_bottom_nav.dart';
import 'package:voosu/presentation/widgets/side_navigation.dart';

void _confirmLogout(BuildContext context) {
  final authBloc = context.read<AuthBloc>();
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Выйти из аккаунта?'),
      content: const Text('Вы уверены, что хотите выйти?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () {
            authBloc.add(const AuthLogoutRequested());
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Выйти', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

class MainLayout extends StatelessWidget {
  const MainLayout({super.key, required this.currentPath});

  final String currentPath;

  NavDestination _destination() =>
      AppRoutes.destinationFromPath(currentPath);

  Widget _tabBody(BuildContext context, NavDestination tab) {
    switch (tab) {
      case NavDestination.chat:
        return const UserChatScreen();
      case NavDestination.projects:
        return const ProjectsScreen();
      case NavDestination.notifications:
        return const _PlaceholderTab(
          icon: Icons.notifications_outlined,
          title: 'Уведомления',
          message: 'Список уведомлений появится здесь позже.',
        );
      case NavDestination.menu:
        return MobileMenuScreen(
          onSelectEditor: () =>
              context.go(AppRoutes.pathForDestination(NavDestination.editor)),
          onLogout: () => _confirmLogout(context),
        );
      case NavDestination.editor:
        return const _PlaceholderTab(
          icon: Icons.edit_note_rounded,
          title: 'Редактор',
          message: 'Раздел в разработке.',
        );
      case NavDestination.admin:
        return const _PlaceholderTab(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Администрирование',
          message: 'Панель администратора в разработке.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final tab = _destination();

    void logout() => _confirmLogout(context);

    final nav = isMobile
        ? AppBottomNav(
            selected: tab,
            onDestinationSelected: (d) =>
                context.go(AppRoutes.pathForDestination(d)),
          )
        : SideNavigation(
            selected: tab,
            onDestinationSelected: (d) =>
                context.go(AppRoutes.pathForDestination(d)),
            onLogout: logout,
          );

    return Scaffold(
      body: isMobile
          ? Column(
              children: [
                Expanded(child: _tabBody(context, tab)),
                nav,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                nav,
                Expanded(child: _tabBody(context, tab)),
              ],
            ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
