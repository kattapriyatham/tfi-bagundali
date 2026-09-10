import "package:go_router/go_router.dart";

import "../ui/home_screen.dart";
import "../ui/settings_screen.dart";
import "../ui/solo_game_screen.dart";
import "../ui/solo_result_screen.dart";
import "../ui/two_player_screen.dart";

abstract final class Routes {
  static const home = "/";
  static const solo = "/solo";
  static const soloResult = "/solo/result";
  static const twoPlayer = "/two-player";
  static const settings = "/settings";
}

final router = GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(path: Routes.home, builder: (_, __) => const HomeScreen()),
    GoRoute(path: Routes.solo, builder: (_, __) => const SoloGameScreen()),
    GoRoute(
      path: Routes.soloResult,
      builder: (_, __) => const SoloResultScreen(),
    ),
    GoRoute(
      path: Routes.twoPlayer,
      builder: (_, __) => const TwoPlayerScreen(),
    ),
    GoRoute(
      path: Routes.settings,
      builder: (_, __) => const SettingsScreen(),
    ),
  ],
);
