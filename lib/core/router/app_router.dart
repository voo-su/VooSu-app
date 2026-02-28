import 'package:go_router/go_router.dart';
import 'package:voosu/presentation/screens/main_layout.dart';
import 'package:voosu/presentation/widgets/side_navigation.dart';

abstract final class AppRoutes {
  static const String chat = 'chat';
  static const String projects = 'projects';

  static const Set<String> _validTabs = {
    chat,
    projects,
  };

  static NavDestination destinationFromPath(String path) {
    final segment = path.startsWith('/') ? path.substring(1) : path;
    final tab = segment.isEmpty ? chat : segment.split('/').first;
    switch (tab) {
      case chat:
        return NavDestination.chat;
      case projects:
        return NavDestination.projects;
      default:
        return NavDestination.chat;
    }
  }

  static String pathForDestination(NavDestination d) {
    switch (d) {
      case NavDestination.chat:
        return '/$chat';
      case NavDestination.projects:
        return '/$projects';
    }
  }

  static bool isValidTab(String tab) => _validTabs.contains(tab);
}

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/${AppRoutes.chat}',
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == '/' || path.isEmpty) return '/${AppRoutes.chat}';
      final segment = path.startsWith('/') ? path.substring(1) : path;
      final tab = segment.split('/').first;
      if (!AppRoutes.isValidTab(tab)) return '/${AppRoutes.chat}';
      return null;
    },
    routes: [
      GoRoute(
        path: '/:tab',
        builder: (context, state) {
          final tab = state.pathParameters['tab'] ?? AppRoutes.chat;
          final path = '/$tab';
          return MainLayout(currentPath: path);
        },
      ),
    ],
  );
}
