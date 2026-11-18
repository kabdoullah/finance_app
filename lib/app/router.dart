import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/accounts/presentation/account_detail_page.dart';
import '../features/accounts/presentation/account_form_page.dart';
import '../features/accounts/presentation/accounts_page.dart';
import '../features/budgets/presentation/budget_form_page.dart';
import '../features/budgets/presentation/budgets_page.dart';
import '../features/categories/presentation/categories_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/forecast/presentation/forecast_page.dart';
import '../features/forecast/presentation/simulation_page.dart';
import '../features/goals/presentation/goal_detail_page.dart';
import '../features/goals/presentation/goal_form_page.dart';
import '../features/goals/presentation/goals_page.dart';
import '../features/recurring/presentation/recurring_auto_recorder.dart';
import '../features/recurring/presentation/recurring_form_page.dart';
import '../features/recurring/presentation/recurring_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/transactions/domain/transaction.dart';
import '../features/transactions/presentation/add_transaction_page.dart';
import '../features/transactions/presentation/transaction_detail_page.dart';
import '../features/transactions/presentation/transactions_page.dart';
import '../l10n/l10n.dart';
import 'app_shell.dart';
import 'coming_soon_page.dart';

/// Chemins de navigation, déclarés en un seul endroit.
abstract final class AppRoutes {
  static const home = '/';
  static const transactions = '/transactions';
  static const budgets = '/budgets';
  static const goals = '/budgets/goals';
  static String goalDetail(String id) => '/budgets/goals/$id';
  static const newGoal = '/goals/new';
  static String newGoalFor({required String name, required int target}) => Uri(
    path: newGoal,
    queryParameters: {'name': name, 'target': '$target'},
  ).toString();
  static const simulation = '/forecast/simulate';
  static String editGoal(String id) => '/goals/$id/edit';
  static const newBudget = '/budgets/new';
  static String editBudget(String id) => '/budgets/$id/edit';
  static const forecast = '/forecast';
  static const assistant = '/assistant';
  static const settings = '/settings';
  static const categories = '/settings/categories';

  static const accounts = '/accounts';
  static const newAccount = '/accounts/new';
  static String accountDetail(String id) => '/accounts/$id';
  static String editAccount(String id) => '/accounts/$id/edit';

  static String newTransaction({TransactionKind? kind, String? accountId}) =>
      Uri(
        path: '/transactions/new',
        queryParameters: {'kind': ?kind?.storageValue, 'account': ?accountId},
      ).toString();
  static String transactionDetail(String id) => '/transactions/$id';
  static const recurring = '/transactions/recurring';
  static String newRecurring({String? fromTransactionId}) => Uri(
    path: '/recurring/new',
    queryParameters: {'from': ?fromTransactionId},
  ).toString();
  static String editRecurring(String id) => '/recurring/$id/edit';
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
        path: '/transactions/new',
        pageBuilder: (context, state) {
          final kind = state.uri.queryParameters['kind'];
          return MaterialPage(
            fullscreenDialog: true,
            child: AddTransactionPage(
              initialKind: kind == null
                  ? TransactionKind.expense
                  : TransactionKind.fromStorage(kind),
              initialAccountId: state.uri.queryParameters['account'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/accounts/:id/edit',
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: AccountFormPage(accountId: state.pathParameters['id']),
        ),
      ),
      GoRoute(
        path: AppRoutes.newBudget,
        pageBuilder: (context, state) =>
            const MaterialPage(fullscreenDialog: true, child: BudgetFormPage()),
      ),
      GoRoute(
        path: '/budgets/:id/edit',
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: BudgetFormPage(budgetId: state.pathParameters['id']),
        ),
      ),
      GoRoute(
        path: '/recurring/new',
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: RecurringFormPage(
            fromTransactionId: state.uri.queryParameters['from'],
          ),
        ),
      ),
      GoRoute(
        path: '/recurring/:id/edit',
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: RecurringFormPage(recurringId: state.pathParameters['id']),
        ),
      ),
      GoRoute(
        path: AppRoutes.newGoal,
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: GoalFormPage(
            initialName: state.uri.queryParameters['name'],
            initialTarget: int.tryParse(
              state.uri.queryParameters['target'] ?? '',
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/goals/:id/edit',
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: GoalFormPage(goalId: state.pathParameters['id']),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            RecurringAutoRecorder(child: AppShell(navigationShell: shell)),
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
                builder: (context, state) => const TransactionsPage(),
                routes: [
                  // Avant « :id » : « recurring » n'est pas une opération.
                  GoRoute(
                    path: 'recurring',
                    builder: (context, state) => const RecurringPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => TransactionDetailPage(
                      transactionId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.budgets,
                builder: (context, state) => const BudgetsPage(),
                routes: [
                  GoRoute(
                    path: 'goals',
                    builder: (context, state) => const GoalsPage(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) =>
                            GoalDetailPage(goalId: state.pathParameters['id']!),
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
                path: AppRoutes.forecast,
                builder: (context, state) => const ForecastPage(),
                routes: [
                  GoRoute(
                    path: 'simulate',
                    builder: (context, state) => const SimulationPage(),
                  ),
                ],
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
        builder: (context, state) => const SettingsPage(),
        routes: [
          GoRoute(
            path: 'categories',
            builder: (context, state) => const CategoriesPage(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
