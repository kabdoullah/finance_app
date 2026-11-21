import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/errors/result.dart';
import '../../../core/money/amount_input_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../l10n/l10n.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../domain/goal_draft.dart';
import '../domain/savings_goal.dart';
import 'goals_providers.dart';

/// Feuille « Ajouter à » / « Retirer de » un objectif (maquettes Objectifs
/// et Objectif-Detail). Affiche le message de confirmation au retour.
Future<void> showGoalMovementSheet(
  BuildContext context,
  SavingsGoal goal,
  GoalMovementKind kind,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final result = await showModalBottomSheet<(Money, SavingsGoal)>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _GoalMovementSheet(goal: goal, kind: kind),
  );
  if (result == null) return;
  final (amount, updated) = result;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          kind == GoalMovementKind.contribution
              ? l10n.goalAddedToast(
                  MoneyFormat.amount(amount),
                  updated.name,
                  MoneyFormat.amount(updated.saved),
                  MoneyFormat.amount(updated.target),
                )
              : l10n.goalWithdrawnToast(MoneyFormat.amount(amount)),
        ),
      ),
    );
}

class _GoalMovementSheet extends ConsumerStatefulWidget {
  const _GoalMovementSheet({required this.goal, required this.kind});

  final SavingsGoal goal;
  final GoalMovementKind kind;

  @override
  ConsumerState<_GoalMovementSheet> createState() => _GoalMovementSheetState();
}

class _GoalMovementSheetState extends ConsumerState<_GoalMovementSheet> {
  static const _quickAdd = [5000, 10000, 25000];
  static const _quickWithdraw = [5000, 10000, 20000];

  final _other = TextEditingController();
  int? _quick = 10000;
  String? _accountId;
  bool _saving = false;
  bool _tooLarge = false;

  bool get _isAdd => widget.kind == GoalMovementKind.contribution;

  Money get _amount =>
      _quick == null ? AmountInputFormatter.parse(_other.text) : Money(_quick!);

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  /// Comptes possibles et leur plafond : le disponible pour une
  /// contribution, la réserve de l'objectif pour un retrait.
  List<(String, String, Money)> _choices() {
    final accounts = ref.watch(activeAccountsProvider).value ?? const [];
    if (_isAdd) {
      final reserved = ref.watch(reservedByAccountProvider).value ?? const {};
      return [
        for (final a in accounts)
          (a.id, a.name, a.balance - (reserved[a.id] ?? Money.zero)),
      ];
    }
    final reserved =
        ref.watch(goalReservedByAccountProvider(widget.goal.id)).value ??
        const {};
    return [
      for (final a in accounts)
        if (reserved[a.id] case final r?) (a.id, a.name, r),
    ];
  }

  Future<void> _confirm(Money amount) async {
    setState(() => _saving = true);
    final repository = ref.read(goalsRepositoryProvider);
    final result = _isAdd
        ? await repository.contribute(widget.goal.id, _accountId!, amount)
        : await repository.withdraw(widget.goal.id, _accountId!, amount);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok(:final value):
        Navigator.of(context).pop((amount, value));
      case Err(failure: ValidationFailure<GoalMovementError>()):
        setState(() => _tooLarge = true);
      case Err():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final goal = widget.goal;
    final choices = _choices();
    final selected =
        choices.where((c) => c.$1 == _accountId).firstOrNull ??
        choices.where((c) => c.$3.value > 0).firstOrNull ??
        choices.firstOrNull;
    _accountId = selected?.$1;
    final limit = selected?.$3 ?? Money.zero;
    final amount = _amount;
    final overLimit = amount.value > limit.value;
    final pace = _isAdd
        ? null
        : ref.watch(goalPaceProvider(goal.id)).value ?? Money.zero;
    // Rythme hebdomadaire = mensuel × 12 ÷ 52.
    final delayWeeks = pace == null || pace.value <= 0
        ? null
        : (amount.value * 52 / (pace.value * 12)).round().clamp(1, 520);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            Text(
              _isAdd
                  ? l10n.goalAddTitle(goal.name)
                  : l10n.goalWithdrawTitle(goal.name),
              style: AppText.sheetTitle,
            ),
            if (_isAdd)
              Text(
                l10n.goalAlreadySaved(
                  MoneyFormat.amount(goal.saved),
                  MoneyFormat.amount(goal.target),
                ),
                style: AppText.bodySmall.copyWith(color: colors.inkSecondary),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in _isAdd ? _quickAdd : _quickWithdraw)
                  if (_isAdd || v <= limit.value)
                    ChoicePill(
                      label: MoneyFormat.amount(Money(v)),
                      selected: _quick == v,
                      onTap: () => setState(() {
                        _quick = v;
                        _tooLarge = false;
                      }),
                    ),
                ChoicePill(
                  label: l10n.goalOtherAmount,
                  selected: _quick == null,
                  onTap: () => setState(() {
                    _quick = null;
                    _tooLarge = false;
                  }),
                ),
              ],
            ),
            if (_quick == null)
              TextField(
                controller: _other,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: const [AmountInputFormatter()],
                onChanged: (_) => setState(() => _tooLarge = false),
                style: AppText.headline,
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: l10n.currencyLabel,
                ),
              ),
            if (choices.isEmpty)
              Text(
                l10n.goalNoAccount,
                style: AppText.bodySmall.copyWith(color: colors.inkSecondary),
              )
            else ...[
              Text(
                _isAdd ? l10n.goalFrom : l10n.goalTo,
                style: AppText.label.medium.copyWith(
                  color: colors.inkSecondary,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (id, name, max) in choices)
                    ChoicePill(
                      label: l10n.goalAccountValue(
                        name,
                        MoneyFormat.amount(max),
                      ),
                      selected: id == _accountId,
                      onTap: () => setState(() {
                        _accountId = id;
                        _tooLarge = false;
                      }),
                    ),
                ],
              ),
            ],
            if (overLimit || _tooLarge)
              Text(
                l10n.goalAmountTooLarge,
                style: AppText.label.copyWith(color: colors.negative),
              )
            else if (!_isAdd && delayWeeks != null && goal.targetDate != null)
              Text(
                l10n.goalWithdrawDelay(delayWeeks),
                style: AppText.bodySmall.prose.copyWith(color: colors.warning),
              ),
            Text(
              l10n.goalReservedNote,
              style: AppText.caption.prose.copyWith(color: colors.inkTertiary),
            ),
            FilledButton(
              onPressed:
                  _saving ||
                      amount.value <= 0 ||
                      overLimit ||
                      _accountId == null
                  ? null
                  : () => _confirm(amount),
              child: Text(
                _isAdd
                    ? l10n.goalAddCta(MoneyFormat.amount(amount))
                    : l10n.goalWithdrawCta(MoneyFormat.amount(amount)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
