import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/clock.dart';
import '../../../core/errors/result.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/money/amount_input_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/field_label.dart';
import '../../../core/widgets/segmented_choice.dart';
import '../../../l10n/l10n.dart';
import '../domain/goal_draft.dart';
import '../domain/savings_goal.dart';
import 'goal_icons.dart';
import 'goals_providers.dart';

/// Création (maquette Objectif-Creer) ou modification d'un objectif.
class GoalFormPage extends ConsumerStatefulWidget {
  const GoalFormPage({
    this.goalId,
    this.initialName,
    this.initialTarget,
    this.initialMonths,
    super.key,
  });

  /// `null` = création.
  final String? goalId;

  /// Création pré-remplie (« Créer un objectif pour cet achat »).
  final String? initialName;
  final int? initialTarget;

  /// Délai pré-choisi en mois (Copilote : « 100 000 en 3 mois »).
  final int? initialMonths;

  @override
  ConsumerState<GoalFormPage> createState() => _GoalFormPageState();
}

class _GoalFormPageState extends ConsumerState<GoalFormPage> {
  /// Échéances proposées à la création, en mois (0 = sans date), plus le
  /// délai demandé au Copilote s'il n'en fait pas partie.
  late final List<int> _dueMonths = [
    ...{3, 6, 12, ?widget.initialMonths}.where((m) => m > 0).toList()..sort(),
    0,
  ];

  final _name = TextEditingController();
  final _target = TextEditingController();
  late bool _initialized = widget.goalId == null;
  bool _saving = false;

  /// Création : nombre de mois choisi.
  late int _months = (widget.initialMonths ?? 0) > 0
      ? widget.initialMonths!
      : 6;

  /// Modification : date précise (`null` = sans date).
  DateTime? _date;
  Set<GoalFieldError> _errors = const {};
  SavingsGoal? _created;

  bool get _isEdit => widget.goalId != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialName case final name?) _name.text = name;
    if (widget.initialTarget case final target? when target > 0) {
      _target.text = MoneyFormat.amount(Money(target));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  DateTime get _today => CalendarDate.of(ref.read(clockProvider)());

  /// Ajoute [months] mois ; un 31 tombe le dernier jour d'un mois court.
  static DateTime _addMonths(DateTime date, int months) {
    final lastDay = DateTime(date.year, date.month + months + 1, 0).day;
    return DateTime(
      date.year,
      date.month + months,
      date.day < lastDay ? date.day : lastDay,
    );
  }

  DateTime? get _targetDate =>
      _isEdit ? _date : (_months == 0 ? null : _addMonths(_today, _months));

  GoalDraft get _draft => GoalDraft(
    name: _name.text,
    target: AmountInputFormatter.parse(_target.text),
    iconKey: goalIconKeyFor(_name.text, context.l10n),
    targetDate: _targetDate,
  );

  Future<void> _submit() async {
    setState(() => _saving = true);
    final repository = ref.read(goalsRepositoryProvider);
    final result = _isEdit
        ? await repository.update(widget.goalId!, _draft)
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
      case Err(failure: ValidationFailure<GoalFieldError>(:final errors)):
        setState(() => _errors = errors);
      case Err():
        _showMessage(context.l10n.errorGeneric);
    }
  }

  Future<void> _delete(SavingsGoal goal) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.goalDeleteTitle,
      message: l10n.goalDeleteBody(MoneyFormat.amount(goal.saved)),
      confirmLabel: l10n.goalDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final result = await ref.read(goalsRepositoryProvider).delete(goal.id);
    if (!mounted) return;
    _showMessage(result is Ok ? l10n.goalDeleted : l10n.errorGeneric);
    if (result is Ok) context.go(AppRoutes.goals);
  }

  Future<void> _pickDate() async {
    final tomorrow = _today.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? _addMonths(_today, 6),
      firstDate: tomorrow,
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = CalendarDate.of(picked);
      _errors = const {};
    });
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  void _change(VoidCallback update) => setState(() {
    update();
    _errors = const {};
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final edited = _isEdit ? ref.watch(goalProvider(widget.goalId!)) : null;
    if (!_initialized) {
      if (edited == null) {
        return Scaffold(appBar: AppBar(leading: const CloseButton()));
      }
      _initialized = true;
      _name.text = edited.name;
      _target.text = MoneyFormat.amount(edited.target);
      _date = edited.targetDate;
    }

    final created = _created;
    final draft = _draft;
    final canSubmit =
        !_saving && draft.normalizedName.isNotEmpty && draft.target.value > 0;

    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text(
          created != null
              ? l10n.goalCreatedTitle
              : _isEdit
              ? l10n.goalEditTitle
              : l10n.goalNewTitle,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: created != null
                  ? _CreatedMessage(goal: created)
                  : _buildForm(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                12,
                AppSpacing.gutter,
                8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  if (created != null)
                    FilledButton(
                      onPressed: () => context.go(AppRoutes.goals),
                      child: Text(l10n.goalSeeAll),
                    )
                  else
                    FilledButton(
                      onPressed: canSubmit ? _submit : null,
                      child: Text(_isEdit ? l10n.goalSave : l10n.goalCreate),
                    ),
                  if (edited != null)
                    TextButton(
                      onPressed: _saving ? null : () => _delete(edited),
                      style: TextButton.styleFrom(
                        foregroundColor: context.colors.negative,
                        minimumSize: const Size(0, 48),
                      ),
                      child: Text(l10n.goalDelete),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final target = AmountInputFormatter.parse(_target.text);
    final surplus = ref.watch(averageSurplusProvider).value;
    final date = _date;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        12,
        AppSpacing.gutter,
        24,
      ),
      children: [
        FieldLabel(l10n.goalNameQuestion),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          maxLength: GoalDraft.maxNameLength,
          onChanged: (_) => _change(() {}),
          decoration: InputDecoration(
            hintText: l10n.goalNameHint,
            counterText: '',
            errorText:
                _errors.contains(GoalFieldError.nameMissing) ||
                    _errors.contains(GoalFieldError.nameTooLong)
                ? l10n.goalErrorName
                : null,
          ),
        ),
        if (!_isEdit) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, iconKey) in goalSuggestions(l10n))
                ChoicePill(
                  label: label,
                  icon: goalIcon(iconKey),
                  selected: _name.text.trim() == label,
                  onTap: () => _change(() => _name.text = label),
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        FieldLabel(l10n.goalTarget),
        TextField(
          controller: _target,
          keyboardType: TextInputType.number,
          inputFormatters: const [AmountInputFormatter()],
          onChanged: (_) => _change(() {}),
          style: AppText.title,
          decoration: InputDecoration(
            hintText: '0',
            suffixText: l10n.currencyLabel,
            suffixStyle: AppText.body.semibold.copyWith(
              color: colors.inkSecondary,
            ),
            errorText:
                _errors.contains(GoalFieldError.targetMissing) ||
                    _errors.contains(GoalFieldError.targetTooLarge)
                ? l10n.goalErrorTarget
                : null,
          ),
        ),
        if (!_isEdit && goalIconKeyFor(_name.text, l10n) == emergencyGoalIcon)
          if (ref.watch(emergencyTargetProvider).value case final suggested?)
            _EmergencySuggestion(
              amount: suggested,
              onUse: () =>
                  _change(() => _target.text = MoneyFormat.amount(suggested)),
            ),
        const SizedBox(height: 20),
        FieldLabel(l10n.goalDueLabel),
        if (_isEdit) ...[
          SegmentedChoice<bool>(
            options: [(true, l10n.goalTargetDate), (false, l10n.goalDueNone)],
            selected: date != null,
            onChanged: (withDate) => _change(
              () => _date = withDate ? (_date ?? _addMonths(_today, 6)) : null,
            ),
          ),
          if (date != null)
            InkWell(
              onTap: _pickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  spacing: 12,
                  children: [
                    Icon(AppIcons.calendarBlank, size: 18, color: colors.ink),
                    Expanded(
                      child: Text(
                        AppDateFormat.dayMonthYear(date, locale),
                        style: AppText.bodyLarge.semibold,
                      ),
                    ),
                    Icon(
                      AppIcons.caretDownBold,
                      size: 14,
                      color: colors.inkTertiary,
                    ),
                  ],
                ),
              ),
            ),
          if (_errors.contains(GoalFieldError.dateInPast))
            Text(
              l10n.goalErrorDate,
              style: AppText.caption.copyWith(color: colors.negative),
            ),
        ] else ...[
          SegmentedChoice<int>(
            options: [
              for (final m in _dueMonths)
                (
                  m,
                  switch (m) {
                    3 => l10n.goalDue3,
                    6 => l10n.goalDue6,
                    12 => l10n.goalDue12,
                    0 => l10n.goalDueNone,
                    _ => l10n.goalDueMonths(m),
                  },
                ),
            ],
            selected: _months,
            onChanged: (m) => _change(() => _months = m),
          ),
          if (target.value > 0 && _months > 0)
            _Plan(
              perMonth: roundUpToHundred(
                Money((target.value / _months).ceil()),
              ),
              surplus: surplus,
            ),
        ],
      ],
    );
  }
}

/// Fonds d'urgence : « 3 mois de tes dépenses ≈ X FCFA. Utiliser ce
/// montant ».
class _EmergencySuggestion extends StatelessWidget {
  const _EmergencySuggestion({required this.amount, required this.onUse});

  final Money amount;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.goalEmergencySuggestion(MoneyFormat.amount(amount)),
            style: AppText.bodySmall.prose.copyWith(
              color: colors.onPrimarySoft,
            ),
          ),
          TextButton(
            onPressed: onUse,
            style: TextButton.styleFrom(
              foregroundColor: colors.onPrimarySoft,
              padding: EdgeInsets.zero,
              textStyle: AppText.bodySmall.semibold,
            ),
            child: Text(l10n.budgetUseAmount),
          ),
        ],
      ),
    );
  }
}

/// « Il faudra mettre de côté environ X FCFA par mois », comparé à ce qu'il
/// reste en moyenne après les dépenses.
class _Plan extends StatelessWidget {
  const _Plan({required this.perMonth, required this.surplus});

  final Money perMonth;
  final Money? surplus;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final average = surplus;
    final tooMuch = average != null && perMonth.value > average.value;
    final text = tooMuch
        ? l10n.goalTooMuch(
            MoneyFormat.amount(perMonth),
            MoneyFormat.amount(average),
          )
        : [
            l10n.goalPlan(MoneyFormat.amount(perMonth)),
            if (average != null && average.value > 0)
              l10n.goalSurplus(MoneyFormat.amount(average)),
          ].join(' ');
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tooMuch ? colors.warningSoft : colors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Icon(
            tooMuch ? AppIcons.warningCircleBold : AppIcons.info,
            size: 17,
            color: tooMuch ? colors.warning : colors.onPrimarySoft,
          ),
          Expanded(
            child: Text(
              text,
              style: AppText.bodySmall.prose.copyWith(
                color: tooMuch ? colors.warning : colors.onPrimarySoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Écran de succès : « Objectif « Téléphone » créé ».
class _CreatedMessage extends StatelessWidget {
  const _CreatedMessage({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = goal.targetDate;
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
              goalIcon(goal.iconKey),
              size: 30,
              color: colors.onPrimarySoft,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.goalCreatedMessage(goal.name),
            textAlign: TextAlign.center,
            style: AppText.title,
          ),
          Text(
            l10n.goalCreatedDetail(
              MoneyFormat.amount(goal.target),
              date == null
                  ? l10n.goalCreatedNoDue
                  : l10n.goalCreatedDue(
                      AppDateFormat.dayMonthYear(date, locale),
                    ),
            ),
            textAlign: TextAlign.center,
            style: AppText.bodyLarge.copyWith(color: colors.inkSecondary),
          ),
        ],
      ),
    );
  }
}
