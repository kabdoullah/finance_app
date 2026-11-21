import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/errors/result.dart';
import '../../../core/money/amount_input_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/field_label.dart';
import '../../../l10n/l10n.dart';
import '../domain/account.dart';
import '../domain/account_draft.dart';
import '../domain/account_type.dart';
import 'account_labels.dart';
import 'accounts_providers.dart';

/// Création (maquette « Nouveau compte ») ou modification d'un compte.
class AccountFormPage extends ConsumerStatefulWidget {
  const AccountFormPage({this.accountId, super.key});

  /// `null` pour une création.
  final String? accountId;

  @override
  ConsumerState<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends ConsumerState<AccountFormPage> {
  final _name = TextEditingController();
  final _balance = TextEditingController();

  AccountType? _type;
  Set<AccountFieldError> _errors = const {};
  bool _saving = false;
  bool _initialized = false;

  /// Compte créé : affiche l'écran de confirmation.
  Account? _created;

  bool get _isEdit => widget.accountId != null;

  @override
  void initState() {
    super.initState();
    _name.addListener(_onChanged);
    _initialized = !_isEdit;
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() => _errors = const {});

  void _fillFrom(Account account) {
    _initialized = true;
    _type = account.type;
    _name.text = account.name;
    _balance.text = account.openingBalance.value == 0
        ? ''
        : MoneyFormat.amount(account.openingBalance);
  }

  AccountDraft get _draft => AccountDraft(
    type: _type,
    name: _name.text,
    openingBalance: AmountInputFormatter.parse(_balance.text),
  );

  bool get _canSubmit =>
      !_saving && _type != null && _draft.normalizedName.isNotEmpty;

  Future<void> _submit() async {
    setState(() => _saving = true);
    final repository = ref.read(accountsRepositoryProvider);
    final result = _isEdit
        ? await repository.update(widget.accountId!, _draft)
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
      case Err(failure: ValidationFailure<AccountFieldError>(:final errors)):
        setState(() => _errors = errors);
      case Err(failure: NotFoundFailure()):
        _showMessage(context.l10n.accountErrorNotFound);
      case Err():
        _showMessage(context.l10n.errorGeneric);
    }
  }

  void _reset() => setState(() {
    _created = null;
    _type = null;
    _name.clear();
    _balance.clear();
    _errors = const {};
  });

  void _showMessage(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (!_initialized) {
      // Modification : pré-remplit le formulaire une seule fois.
      final account = ref.watch(accountProvider(widget.accountId!)).value;
      if (account == null) return Scaffold(appBar: AppBar());
      _fillFrom(account);
    }

    final created = _created;
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text(
          created != null
              ? l10n.accountCreatedTitle
              : _isEdit
              ? l10n.accountEditTitle
              : l10n.accountNewTitle,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: created != null
                  ? _CreatedMessage(account: created)
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
                children: created != null
                    ? [
                        FilledButton(
                          onPressed: () => context.go(AppRoutes.accounts),
                          child: Text(l10n.accountSeeAll),
                        ),
                        TextButton(
                          onPressed: _reset,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            textStyle: AppText.bodyLarge.semibold,
                          ),
                          child: Text(l10n.accountAddAnother),
                        ),
                      ]
                    : [
                        FilledButton(
                          onPressed: _canSubmit ? _submit : null,
                          child: Text(
                            _isEdit ? l10n.accountSave : l10n.accountCreate,
                          ),
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
    final type = _type;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        12,
        AppSpacing.gutter,
        24,
      ),
      children: [
        FieldLabel(l10n.accountFieldType),
        // Deux tuiles par rangée ; hauteur minimale de 84 px, extensible
        // (libellé sur deux lignes, grande taille de texte).
        Column(
          spacing: 8,
          children: [
            for (var i = 0; i < accountTypeFormOrder.length; i += 2)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    for (final option in accountTypeFormOrder.skip(i).take(2))
                      Expanded(
                        child: _TypeTile(
                          type: option,
                          selected: option == type,
                          onTap: () => setState(() {
                            _type = option;
                            _errors = const {};
                          }),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        if (type == AccountType.mobileMoney) ...[
          const SizedBox(height: 24),
          FieldLabel(l10n.accountFieldOperator),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final operator in mobileMoneyOperators)
                ChoicePill(
                  label: operator,
                  selected: _draft.normalizedName == operator,
                  onTap: () => _name.text = operator,
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        FieldLabel(l10n.accountFieldName),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          style: AppText.bodyLarge,
          decoration: InputDecoration(
            hintText: type?.nameHint(l10n) ?? l10n.accountNameHintNone,
            errorText: _nameError(l10n),
          ),
        ),
        const SizedBox(height: 24),
        FieldLabel(
          _isEdit
              ? l10n.accountFieldOpeningBalance
              : l10n.accountFieldCurrentBalance,
        ),
        TextField(
          controller: _balance,
          // Le solde initial ne se modifie plus après la création.
          enabled: !_isEdit,
          keyboardType: TextInputType.number,
          inputFormatters: const [AmountInputFormatter()],
          onChanged: (_) => _onChanged(),
          style: AppText.sectionTitle,
          decoration: InputDecoration(
            hintText: '0',
            suffixText: l10n.currencyLabel,
            suffixStyle: AppText.body.semibold.copyWith(
              color: colors.inkSecondary,
            ),
            errorText: _errors.contains(AccountFieldError.openingBalanceInvalid)
                ? l10n.accountErrorOpeningBalance
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isEdit
              ? l10n.accountOpeningBalanceLocked
              : l10n.accountOpeningBalanceHelp,
          style: AppText.caption.prose.copyWith(color: colors.inkTertiary),
        ),
      ],
    );
  }

  String? _nameError(AppLocalizations l10n) {
    if (_errors.contains(AccountFieldError.nameTaken)) {
      return l10n.accountErrorNameTaken;
    }
    if (_errors.contains(AccountFieldError.nameTooLong)) {
      return l10n.accountErrorNameTooLong;
    }
    if (_errors.contains(AccountFieldError.nameMissing)) {
      return l10n.accountErrorNameMissing;
    }
    return null;
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final AccountType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: selected
          ? BorderSide(color: colors.primary, width: 2)
          : BorderSide(color: colors.line),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.primarySoft : colors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 84),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 8,
                children: [
                  Icon(
                    type.icon,
                    size: 22,
                    color: selected
                        ? colors.onPrimarySoft
                        : colors.inkSecondary,
                  ),
                  Text(
                    type.label(context.l10n),
                    style: AppText.bodyLarge.semibold,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreatedMessage extends StatelessWidget {
  const _CreatedMessage({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
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
            l10n.accountCreatedMessage(account.name),
            textAlign: TextAlign.center,
            style: AppText.title,
          ),
          Text(
            l10n.accountCreatedBalance(
              MoneyFormat.amount(account.openingBalance),
            ),
            textAlign: TextAlign.center,
            style: AppText.bodyLarge.copyWith(color: colors.inkSecondary),
          ),
        ],
      ),
    );
  }
}
