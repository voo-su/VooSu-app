import 'package:flutter/material.dart';
import 'package:voosu/core/theme/app_theme.dart';
import 'package:voosu/presentation/widgets/side_navigation.dart';

class AppBottomNav extends StatelessWidget {
  final NavDestination selected;
  final ValueChanged<NavDestination> onDestinationSelected;
  final Widget? trailing;

  const AppBottomNav({
    super.key,
    required this.selected,
    required this.onDestinationSelected,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.railBackground(context),
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.chat_bubble_outline,
                selectedIcon: Icons.chat_bubble,
                label: 'Чаты',
                isSelected: selected == NavDestination.chat,
                onTap: () => onDestinationSelected(NavDestination.chat),
              ),
              _NavItem(
                icon: Icons.folder_outlined,
                selectedIcon: Icons.folder,
                label: 'Проекты',
                isSelected: selected == NavDestination.projects,
                onTap: () => onDestinationSelected(NavDestination.projects),
              ),
              _NavItem(
                icon: Icons.menu_rounded,
                selectedIcon: Icons.menu_rounded,
                label: 'Меню',
                isSelected: selected == NavDestination.menu,
                onTap: () => onDestinationSelected(NavDestination.menu),
              ),
              ...[if (trailing != null) trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isSelected ? selectedIcon : icon, size: 26, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
