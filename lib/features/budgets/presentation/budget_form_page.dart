import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/errors/result.dart';
import '../../../core/money/amount_input_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/field_label.dart';
import '../../../core/widgets/segmented_choice.dart';
import '../../../l10n/l10n.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_providers.dart';
import '../../categories/presentation/category_icons.dart';
import '../domain/budget.dart';
import '../domain/budget_draft.dart';
import 'budgets_providers.dart';

/// Création (maquette Budget-Creer) ou modification d'un budget.
class BudgetFormPage extends ConsumerStatefulWidget {
  const BudgetFormPage({this.budgetId, super.key});

  /// `null` = création.
  final String? budgetId;

  @override
  ConsumerState<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends ConsumerState<BudgetFormPage> {
  static const _alertOptions = [50, 80, 90, 100];

  final _limit = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  /// Budget qui vient d'être créé : affiche l'écran de succès.
  Budget? _created;

  /// Catégorie choisie ; `null` = toutes les dépenses (si [_pickedGlobal]).
  String? _categoryId;
  bool _pickedGlobal = false;
  int _alertPercent = BudgetDraft.defaultAlertPercent;
  Set<BudgetFieldError> _errors = const {};

  bool get _isEdit => widget.budgetId != null;
  bool get _hasTarget => _pickedGlobal || _categoryId != null;

  @override
  void initState() {
    super.initState();
    _initialized = !_isEdit;
  }

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  BudgetDraft get _draft => BudgetDraft(
    limit: AmountInputFormatter.parse(_limit.text),
    categoryId: _pickedGlobal ? null : _categoryId,
    alertPercent: _alertPercent,
  );

  Future<void> _submit() async {
    setState(() => _saving = true);
    final repository = ref.read(budgetsRepositoryProvider);
    final result = _isEdit
        ? await repository.update(widget.budgetId!, _draft)
        : await repository.create(_draft);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok(:final value):
        if (_isEdit) {
          context.pop();
        } else {
          setState(() => _created = value);
        }
      case Err(failure: ValidationFailure<BudgetFieldError>(:final errors)):
        setState(() => _errors = errors);
      case Err():
        _showMessage(context.l10n.errorGeneric);
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.budgetDeleteTitle,
      message: l10n.budgetDeleteBody,
      confirmLabel: l10n.budgetDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final result = await ref
        .read(budgetsRepositoryProvider)
        .delete(widget.budgetId!);
    if (!mounted) return;
    _showMessage(result is Ok ? l10n.budgetDeleted : l10n.errorGeneric);
    if (result is Ok) context.pop();
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  void _reset() => setState(() {
    _created = null;
    _categoryId = null;
    _pickedGlobal = false;
    _alertPercent = BudgetDraft.defaultAlertPercent;
    _limit.clear();
    _errors = const {};
  });

  void _useAmount(Money amount) => setState(() {
    _limit.text = MoneyFormat.amount(amount);
    _errors = const {};
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final budgets = ref.watch(budgetsProvider).value;
    final groups = ref
        .watch(categoryGroupsProvider(CategoryKind.expense))
        .value;
    if (budgets == null || groups == null) {
      return Scaffold(appBar: AppBar(leading: const CloseButton()));
    }

    Budget? edited;
    if (_isEdit) {
      edited = budgets.where((b) => b.id == widget.budgetId).firstOrNull;
      if (edited == null) {
        return Scaffold(appBar: AppBar(leading: const CloseButton()));
      }
      if (!_initialized) {
        _initialized = true;
        _categoryId = edited.category?.id;
        _pickedGlobal = edited.isGlobal;
        _alertPercent = edited.alertPercent;
        _limit.text = MoneyFormat.amount(edited.limit);
      }
    }

    final created = _created;
    final canSubmit =
        !_saving &&
        _hasTarget &&
        AmountInputFormatter.parse(_limit.text).value > 0;

    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text(
          created != null
              ? l10n.budgetCreatedTitle
              : _isEdit
              ? l10n.budgetEditTitle
              : l10n.budgetNewTitle,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: created != null
                  ? _CreatedMessage(budget: created)
                  : _buildForm(context, budgets, groups, edited),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  if (created != null) ...[
                    FilledButton(
                      onPressed: () => context.pop(),
                      child: Text(l10n.budgetSeeAll),
                    ),
                    TextButton(
                      onPressed: _reset,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        textStyle: AppText.bodyLarge.semibold,
                      ),
                      child: Text(l10n.budgetAddAnother),
                    ),
                  ] else
                    FilledButton(
                      onPressed: canSubmit ? _submit : null,
                      child: Text(
                        _isEdit ? l10n.budgetSaveChanges : l10n.budgetSave,
                      ),
                    ),
                  if (_isEdit)
                    TextButton(
                      onPressed: _saving ? null : _delete,
                      style: TextButton.styleFrom(
                        foregroundColor: context.colors.negative,
                        minimumSize: const Size(0, 48),
                      ),
                      child: Text(l10n.budgetDelete),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    List<Budget> budgets,
    List<CategoryGroup> groups,
    Budget? edited,
  ) {
    final colors = context.colors;
    final l10n = context.l10n;
    final tracked = {for (final b in budgets) b.category?.id};
    final hasGlobal = budgets.any((b) => b.isGlobal);
    final available = [
      for (final g in groups)
        if (!g.category.isHidden && !tracked.contains(g.category.id))
          g.category,
    ];
    final trackedNames = [
      for (final b in budgets)
        if (b.category case final c?) c.name,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        FieldLabel(l10n.txCategory),
        if (edited != null)
          Text(
            edited.category?.name ?? l10n.budgetAllExpenses,
            style: AppText.sectionTitle,
          )
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!hasGlobal)
                ChoicePill(
                  label: l10n.budgetAllExpenses,
                  selected: _pickedGlobal,
                  onTap: () => setState(() {
                    _pickedGlobal = true;
                    _categoryId = null;
                    _errors = const {};
                  }),
                ),
              for (final c in available)
                ChoicePill(
                  label: c.name,
                  icon: categoryIcon(c.iconKey),
                  selected: !_pickedGlobal && _categoryId == c.id,
                  onTap: () => setState(() {
                    _pickedGlobal = false;
                    _categoryId = c.id;
                    _errors = const {};
                  }),
                ),
            ],
          ),
          if (trackedNames.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l10n.budgetAlreadyTracked(trackedNames.join(', ')),
              style: AppText.caption.copyWith(color: colors.inkTertiary),
            ),
          ],
          if (_errors.contains(BudgetFieldError.alreadyExists) ||
              _errors.contains(BudgetFieldError.categoryInvalid)) ...[
            const SizedBox(height: 6),
            Text(
              _errors.contains(BudgetFieldError.alreadyExists)
                  ? l10n.budgetErrorExists
                  : l10n.budgetErrorCategory,
              style: AppText.caption.copyWith(color: colors.negative),
            ),
          ],
        ],
        const SizedBox(height: 24),
        FieldLabel(l10n.budgetLimit),
        TextField(
          controller: _limit,
          keyboardType: TextInputType.number,
          inputFormatters: const [AmountInputFormatter()],
          onChanged: (_) => setState(() => _errors = const {}),
          style: AppText.sectionTitle,
          decoration: InputDecoration(
            hintText: '0',
            suffixText: l10n.currencyLabel,
            suffixStyle: AppText.body.semibold.copyWith(
              color: colors.inkSecondary,
            ),
            errorText:
                _errors.contains(BudgetFieldError.limitMissing) ||
                    _errors.contains(BudgetFieldError.limitTooLarge)
                ? l10n.budgetErrorLimit
                : null,
          ),
        ),
        if (_hasTarget)
          _AverageHint(
            categoryId: _pickedGlobal ? null : _categoryId,
            onUse: _useAmount,
          ),
        const SizedBox(height: 24),
        FieldLabel(l10n.budgetPeriod),
        Text(
          l10n.budgetPeriodMonthly,
          style: AppText.bodyLarge.copyWith(color: colors.inkSecondary),
        ),
        const SizedBox(height: 24),
        FieldLabel(l10n.budgetAlertAt),
        SegmentedChoice<int>(
          options: [for (final p in _alertOptions) (p, '$p %')],
          selected: _alertPercent,
          onChanged: (p) => setState(() => _alertPercent = p),
        ),
      ],
    );
  }
}

/// Écran de succès (maquette Budget-Creer) : « Budget Transport créé ».
class _CreatedMessage extends StatelessWidget {
  const _CreatedMessage({required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final category = budget.category;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 24),
      child: Column(
        spacing: 10,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primarySoft,
            ),
            child: Icon(
              AppIcons.checkBold,
              size: 32,
              color: colors.onPrimarySoft,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            category == null
                ? l10n.budgetCreatedGlobal
                : l10n.budgetCreatedMessage(category.name),
            textAlign: TextAlign.center,
            style: AppText.title,
          ),
          Text(
            l10n.budgetCreatedDetail(
              MoneyFormat.amount(budget.limit),
              budget.alertPercent,
            ),
            textAlign: TextAlign.center,
            style: AppText.bodyLarge.copyWith(color: colors.inkSecondary),
          ),
        ],
      ),
    );
  }
}

/// « Ces 3 derniers mois, tu as dépensé en moyenne X FCFA. Utiliser ce
/// montant » — masqué s'il n'y a pas d'historique.
class _AverageHint extends ConsumerWidget {
  const _AverageHint({required this.categoryId, required this.onUse});

  final String? categoryId;
  final ValueChanged<Money> onUse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final average = ref.watch(averageSpendingProvider(categoryId)).value;
    if (average == null || average.value <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.budgetAverage(MoneyFormat.amount(average)),
              style: AppText.bodySmall.prose.copyWith(
                color: colors.onPrimarySoft,
              ),
            ),
            TextButton(
              onPressed: () => onUse(average),
              style: TextButton.styleFrom(
                foregroundColor: colors.onPrimarySoft,
                padding: EdgeInsets.zero,
                textStyle: AppText.bodySmall.semibold,
              ),
              child: Text(l10n.budgetUseAmount),
            ),
          ],
        ),
      ),
    );
  }
}
