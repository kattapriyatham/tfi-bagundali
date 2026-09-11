import "package:go_router/go_router.dart";

import "../ui/home_screen.dart";
import "../ui/online/create_join_screen.dart";
import "../ui/online/online_game_screen.dart";
import "../ui/online/online_lobby_screen.dart";
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
  static const online = "/online";
  static String onlineLobby(String code) => "/online/lobby/$code";
  static String onlineGame(String code) => "/online/game/$code";
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
    GoRoute(path: Routes.online, builder: (_, __) => const CreateJoinScreen()),
    GoRoute(
      path: "/online/lobby/:code",
      builder: (_, state) =>
          OnlineLobbyScreen(code: state.pathParameters["code"]!),
    ),
    GoRoute(
      path: "/online/game/:code",
      builder: (_, state) =>
          OnlineGameScreen(code: state.pathParameters["code"]!),
    ),
  ],
);
