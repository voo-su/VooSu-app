import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voosu/core/layout/responsive.dart';
import 'package:voosu/core/router/app_router.dart';
import 'package:voosu/presentation/screens/chat/chat_screen.dart';
import 'package:voosu/presentation/screens/menu/mobile_menu_screen.dart';
import 'package:voosu/presentation/screens/profile/profile_screen.dart';
import 'package:voosu/presentation/screens/projects/projects_screen.dart';
import 'package:voosu/presentation/widgets/app_bottom_nav.dart';
import 'package:voosu/presentation/widgets/connection_status_bar.dart';
import 'package:voosu/presentation/widgets/side_navigation.dart';

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
      case NavDestination.profile:
        return const ProfileScreen();
      case NavDestination.menu:
        return MobileMenuScreen(
          onSelectProfile: () => context.go(AppRoutes.pathForDestination(NavDestination.profile)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final tab = _destination();

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
          );

    return Scaffold(
      body: Stack(
        children: [
          isMobile
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
          const ConnectionStatusBar(showInScaffold: true),
        ],
      ),
    );
  }
}
