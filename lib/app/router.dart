import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/accounts/presentation/account_detail_page.dart';
import '../features/accounts/presentation/account_form_page.dart';
import '../features/accounts/presentation/accounts_page.dart';
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

  static const accounts = '/accounts';
  static const newAccount = '/accounts/new';
  static String accountDetail(String id) => '/accounts/$id';
  static String editAccount(String id) => '/accounts/$id/edit';
}

/// Routeur de l'application : 5 onglets (chacun garde sa pile de navigation)
/// et des écrans plein écran au-dessus (paramètres, puis saisie, détails…).
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      // Écrans plein écran (sans barre basse). Déclarés avant les onglets :
      // « /accounts/new » ne doit pas être lu comme le compte d'id « new ».
      GoRoute(
        path: AppRoutes.newAccount,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: AccountFormPage(),
        ),
      ),
      GoRoute(
        path: '/accounts/:id/edit',
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: AccountFormPage(accountId: state.pathParameters['id']),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const DashboardPage(),
                routes: [
                  // Comptes : dans l'onglet Accueil (barre basse visible).
                  GoRoute(
                    path: 'accounts',
                    builder: (context, state) => const AccountsPage(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => AccountDetailPage(
                          accountId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
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
