import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/core/layout/responsive.dart';
import 'package:voosu/core/router/app_router.dart';
import 'package:voosu/data/services/upload_queue_service.dart';
import 'package:voosu/presentation/widgets/upload_queue_panel.dart';
import 'package:voosu/presentation/screens/chat/chat_screen.dart';
import 'package:voosu/presentation/screens/contacts/contacts_screen.dart';
import 'package:voosu/presentation/screens/search/global_user_search_screen.dart';
import 'package:voosu/presentation/screens/search/search_public_groups_screen.dart';
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
      case NavDestination.contacts:
        return const ContactsScreen();
      case NavDestination.searchGroups:
        return const SearchPublicGroupsScreen();
      case NavDestination.userSearch:
        return const GlobalUserSearchScreen();
      case NavDestination.profile:
        return const ProfileScreen();
      case NavDestination.menu:
        return MobileMenuScreen(
          onSelectProfile: () =>
              context.go(AppRoutes.pathForDestination(NavDestination.profile)),
          onSelectSearchGroups: () => context.go(
            AppRoutes.pathForDestination(NavDestination.searchGroups),
          ),
          onSelectUserSearch: () => context.go(
            AppRoutes.pathForDestination(NavDestination.userSearch),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final tab = _destination();

    return ListenableBuilder(
      listenable: di.sl<UploadQueueService>(),
      builder: (context, _) {
        final uploadQueue = di.sl<UploadQueueService>();
        final uploadSlot = uploadQueue.panelVisible
            ? UploadQueueNavButton(service: uploadQueue)
            : null;

        final nav = isMobile
            ? AppBottomNav(
                selected: tab,
                onDestinationSelected: (d) =>
                    context.go(AppRoutes.pathForDestination(d)),
                uploadQueueSlot: uploadSlot,
              )
            : SideNavigation(
                selected: tab,
                onDestinationSelected: (d) =>
                    context.go(AppRoutes.pathForDestination(d)),
                uploadQueueSlot: uploadSlot,
              );

        return _buildScaffold(context, isMobile, tab, nav);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    bool isMobile,
    NavDestination tab,
    Widget nav,
  ) {
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

