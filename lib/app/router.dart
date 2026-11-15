import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_page.dart';
import '../l10n/l10n.dart';
import 'app_shell.dart';
import 'coming_soon_page.dart';

/// Chemins de navigation, déclarés en un seul endroit.
abstract final class AppRoutes {
  static const home = '/';
  static const transactions = '/transactions';
  static const budgets = '/budgets';
  static const forecast = '/forecast';
  static const assistant = '/assistant';
  static const settings = '/settings';
}

/// Routeur de l'application : 5 onglets (chacun garde sa pile de navigation)
/// et des écrans plein écran au-dessus (paramètres, puis saisie, détails…).
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transactions,
                builder: (context, state) =>
                    ComingSoonPage(title: context.l10n.navTransactions),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.budgets,
                builder: (context, state) =>
                    ComingSoonPage(title: context.l10n.navBudgets),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.forecast,
                builder: (context, state) =>
                    ComingSoonPage(title: context.l10n.navForecast),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.assistant,
                builder: (context, state) =>
                    ComingSoonPage(title: context.l10n.navAssistant),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => ComingSoonPage(
          title: context.l10n.settingsTitle,
          showAppBar: true,
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
