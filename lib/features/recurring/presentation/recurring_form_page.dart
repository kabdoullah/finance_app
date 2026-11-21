import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
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
import '../../accounts/presentation/accounts_providers.dart';
import '../../categories/presentation/categories_providers.dart';
import '../../categories/presentation/category_icons.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/presentation/transaction_labels.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../domain/recurrence.dart';
import '../domain/recurring_draft.dart';
import '../domain/recurring_operation.dart';
import 'recurring_labels.dart';
import 'recurring_providers.dart';

/// Création (maquette Recurrente-Creer), modification d'un modèle, ou
/// « Rendre récurrente » une opération existante.
class RecurringFormPage extends ConsumerStatefulWidget {
  const RecurringFormPage({
    this.recurringId,
    this.fromTransactionId,
    super.key,
  });

  /// Modèle à modifier ; `null` = création.
  final String? recurringId;

  /// Opération qui pré-remplit la création (« Rendre récurrente »).
  final String? fromTransactionId;

  @override
  ConsumerState<RecurringFormPage> createState() => _RecurringFormPageState();
}

class _RecurringFormPageState extends ConsumerState<RecurringFormPage> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  late bool _initialized =
      widget.recurringId == null && widget.fromTransactionId == null;
  bool _saving = false;

  TransactionKind _kind = TransactionKind.expense;
  bool _isVariable = false;
  String? _categoryId;
  String? _accountId;
  RecurrenceFrequency _frequency = RecurrenceFrequency.month;
  late DateTime _start = CalendarDate.of(ref.read(clockProvider)());
  DateTime? _end;
  bool _ask = true;
  Set<RecurringFieldError> _errors = const {};

  /// Modèle qui vient d'être programmé : affiche l'écran de succès.
  RecurringOperation? _created;

  bool get _isEdit => widget.recurringId != null;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _fillFromOperation(RecurringOperation o) {
    _kind = o.kind;
    _name.text = o.name;
    _amount.text = MoneyFormat.amount(o.amount);
    _isVariable = o.isVariable;
    _categoryId = o.category.id;
    _accountId = o.accountId;
    _frequency = o.recurrence.frequency;
    _start = o.recurrence.start;
    _end = o.recurrence.end;
    _ask = o.askBeforeRecording;
  }

  /// « Rendre récurrente » : même opération, chaque mois à partir du mois
  /// suivant.
  void _fillFromTransaction(Transaction t) {
    final date = t.occurredAt.toLocal();
    _kind = t.kind == TransactionKind.income
        ? TransactionKind.income
        : TransactionKind.expense;
    _name.text = t.description ?? t.mainCategory?.name ?? '';
    _amount.text = MoneyFormat.amount(t.amount);
    _categoryId = t.category?.id;
    _accountId = t.accountId;
    _start = Recurrence(
      frequency: RecurrenceFrequency.month,
      start: CalendarDate.of(date),
    ).occurrence(1);
  }

  RecurringDraft get _draft => RecurringDraft(
    kind: _kind,
    name: _name.text,
    amount: AmountInputFormatter.parse(_amount.text),
    isVariable: _isVariable,
    categoryId: _categoryId,
    accountId: _accountId,
    frequency: _frequency,
    startDate: _start,
    endDate: _end,
    askBeforeRecording: _ask,
  );

  Future<void> _submit() async {
    setState(() => _saving = true);
    final repository = ref.read(recurringRepositoryProvider);
    final result = _isEdit
        ? await repository.update(widget.recurringId!, _draft)
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
      case Err(failure: ValidationFailure<RecurringFieldError>(:final errors)):
        setState(() => _errors = errors);
      case Err():
        _showMessage(context.l10n.errorGeneric);
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.recurringDeleteTitle,
      message: l10n.recurringDeleteBody,
      confirmLabel: l10n.recurringDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final result = await ref
        .read(recurringRepositoryProvider)
        .delete(widget.recurringId!);
    if (!mounted) return;
    _showMessage(result is Ok ? l10n.recurringDeleted : l10n.errorGeneric);
    if (result is Ok) context.pop();
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _start = CalendarDate.of(picked);
      final end = _end;
      if (end != null && end.isBefore(_start)) _end = _start;
      _errors = const {};
    });
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end ?? _start,
      firstDate: _start,
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _end = CalendarDate.of(picked);
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
    if (!_initialized) {
      final source = _isEdit
          ? ref
                .watch(recurringOperationsProvider)
                .value
                ?.where((o) => o.id == widget.recurringId)
                .firstOrNull
          : null;
      final transaction = widget.fromTransactionId == null
          ? null
          : ref.watch(transactionProvider(widget.fromTransactionId!)).value;
      if (source == null && transaction == null) {
        return Scaffold(appBar: AppBar(leading: const CloseButton()));
      }
      _initialized = true;
      if (source != null) _fillFromOperation(source);
      if (transaction != null) _fillFromTransaction(transaction);
    }

    final created = _created;
    final draft = _draft;
    final canSubmit =
        !_saving &&
        draft.normalizedName.isNotEmpty &&
        draft.amount.value > 0 &&
        _categoryId != null &&
        _accountId != null;

    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text(
          created != null
              ? l10n.recurringCreatedTitle
              : _isEdit
              ? l10n.recurringEditTitle
              : l10n.recurringNewTitle,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: created != null
                  ? _CreatedMessage(operation: created)
                  : _buildForm(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  if (created != null)
                    FilledButton(
                      onPressed: () => context.go(AppRoutes.recurring),
                      child: Text(l10n.recurringSeeAll),
                    )
                  else
                    FilledButton(
                      onPressed: canSubmit ? _submit : null,
                      child: Text(
                        _isEdit
                            ? l10n.recurringSaveChanges
                            : l10n.recurringSave,
                      ),
                    ),
                  if (_isEdit)
                    TextButton(
                      onPressed: _saving ? null : _delete,
                      style: TextButton.styleFrom(
                        foregroundColor: context.colors.negative,
                        minimumSize: const Size(0, 48),
                      ),
                      child: Text(l10n.recurringDelete),
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
    final categoryKind = _kind.categoryKind!;
    final groups = ref.watch(categoryGroupsProvider(categoryKind)).value ?? [];
    final accounts = ref.watch(activeAccountsProvider).value ?? [];
    final recurrence = _draft.recurrence;
    final count = recurrence.count;
    final end = _end;
    String? error(Set<RecurringFieldError> keys, String message) =>
        _errors.any(keys.contains) ? message : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        SegmentedChoice<TransactionKind>(
          options: [
            for (final kind in [
              TransactionKind.expense,
              TransactionKind.income,
            ])
              (kind, kind.label(l10n)),
          ],
          selected: _kind,
          onChanged: (kind) => _change(() {
            if (kind != _kind) _categoryId = null;
            _kind = kind;
          }),
        ),
        const SizedBox(height: 20),
        FieldLabel(l10n.recurringName),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          maxLength: RecurringDraft.maxNameLength,
          onChanged: (_) => _change(() {}),
          decoration: InputDecoration(
            hintText: l10n.recurringNameHint,
            counterText: '',
            errorText: error({
              RecurringFieldError.nameMissing,
              RecurringFieldError.nameTooLong,
            }, l10n.recurringErrorName),
          ),
        ),
        const SizedBox(height: 18),
        FieldLabel(l10n.recurringAmount),
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          inputFormatters: const [AmountInputFormatter()],
          onChanged: (_) => _change(() {}),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: '0',
            suffixText: l10n.currencyLabel,
            suffixStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.inkSecondary,
            ),
            errorText: error({
              RecurringFieldError.amountMissing,
              RecurringFieldError.amountTooLarge,
            }, l10n.recurringErrorAmount),
          ),
        ),
        const SizedBox(height: 8),
        _SwitchRow(
          title: l10n.recurringVariable,
          subtitle: l10n.recurringVariableHelp,
          value: _isVariable,
          onChanged: (v) => _change(() => _isVariable = v),
        ),
        const SizedBox(height: 18),
        FieldLabel(l10n.txCategory),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in groups)
              if (!g.category.isHidden || g.category.id == _categoryId)
                ChoicePill(
                  label: g.category.name,
                  icon: categoryIcon(g.category.iconKey),
                  selected:
                      _categoryId == g.category.id ||
                      g.children.any((c) => c.id == _categoryId),
                  onTap: () => _change(() => _categoryId = g.category.id),
                ),
          ],
        ),
        if (error({
              RecurringFieldError.categoryMissing,
              RecurringFieldError.categoryInvalid,
            }, l10n.recurringErrorCategory)
            case final message?)
          _ErrorText(message),
        const SizedBox(height: 18),
        FieldLabel(l10n.txAccount),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in accounts)
              ChoicePill(
                label: a.name,
                selected: _accountId == a.id,
                onTap: () => _change(() => _accountId = a.id),
              ),
          ],
        ),
        if (error({
              RecurringFieldError.accountMissing,
              RecurringFieldError.accountUnavailable,
            }, l10n.recurringErrorAccount)
            case final message?)
          _ErrorText(message),
        const SizedBox(height: 18),
        FieldLabel(l10n.recurringFrequency),
        SegmentedChoice<RecurrenceFrequency>(
          options: [
            for (final f in RecurrenceFrequency.values) (f, f.label(l10n)),
          ],
          selected: _frequency,
          onChanged: (f) => _change(() => _frequency = f),
        ),
        const SizedBox(height: 8),
        _DateRow(
          icon: AppIcons.calendarBlank,
          label: l10n.recurringDue,
          value: recurrence.dueLabel(l10n, locale),
        ),
        _DateRow(
          icon: AppIcons.play,
          label: l10n.recurringStart,
          value: AppDateFormat.dayMonthYear(_start, locale),
          onTap: _pickStart,
        ),
        const SizedBox(height: 18),
        FieldLabel(l10n.recurringEnd),
        SegmentedChoice<bool>(
          options: [
            (false, l10n.recurringNoEnd),
            (true, l10n.recurringEndOnDate),
          ],
          selected: end != null,
          onChanged: (hasEnd) => _change(
            () => _end = hasEnd ? (_end ?? recurrence.occurrence(11)) : null,
          ),
        ),
        if (end != null && count != null)
          _DateRow(
            icon: AppIcons.stop,
            label: l10n.recurringLastDue,
            value: l10n.recurringLastDueValue(
              AppDateFormat.dayMonthYear(
                recurrence.occurrence(count - 1),
                locale,
              ),
              count,
            ),
            onTap: _pickEnd,
          ),
        if (error({RecurringFieldError.endBeforeStart}, l10n.recurringErrorEnd)
            case final message?)
          _ErrorText(message),
        const SizedBox(height: 18),
        _SwitchRow(
          title: l10n.recurringAsk,
          subtitle: _ask ? l10n.recurringAskOn : l10n.recurringAskOff,
          value: _ask,
          onChanged: (v) => _change(() => _ask = v),
        ),
      ],
    );
  }
}

/// Écran de succès : « « Tontine du quartier » programmée ».
class _CreatedMessage extends StatelessWidget {
  const _CreatedMessage({required this.operation});

  final RecurringOperation operation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final meta = operation.recurrence.meta(l10n, locale);
    final schedule = meta[0].toLowerCase() + meta.substring(1);
    final next = operation.nextDue;
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
              AppIcons.repeatBold,
              size: 30,
              color: colors.onPrimarySoft,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.recurringCreatedMessage(operation.name),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          Text(
            [
              l10n.recurringCreatedSummary(
                operation.signedAmount,
                schedule,
                operation.accountName,
              ),
              if (next != null)
                l10n.recurringCreatedNext(
                  AppDateFormat.dayMonthYear(next, locale),
                ),
            ].join('\n'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: colors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: TextStyle(fontSize: 12.5, color: context.colors.negative),
    ),
  );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Row(
      spacing: 12,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: context.colors.inkTertiary,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    ),
  );
}

/// Ligne « Échéance / Début / Dernière échéance » des maquettes.
class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.line)),
        ),
        child: Row(
          spacing: 12,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.chip,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: colors.ink),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 1,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.inkSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(AppIcons.caretDownBold, size: 14, color: colors.inkTertiary),
          ],
        ),
      ),
    );
  }
}
