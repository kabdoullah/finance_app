import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../core/errors/result.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/segmented_choice.dart';
import '../../../l10n/l10n.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../domain/category.dart';
import '../domain/category_draft.dart';
import 'category_icons.dart';

/// Gestion des catégories (maquette Catégories).
class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  CategoryKind _kind = CategoryKind.expense;

  /// Catégorie dépliée (une seule à la fois, comme la maquette).
  String? _openId;

  void _showMessage(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _create({Category? parent}) async {
    final groups = ref.read(categoryGroupsProvider(_kind)).value ?? const [];
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      builder: (_) => _CategorySheet(
        kind: _kind,
        parents: [
          for (final g in groups)
            if (!g.category.isHidden) g.category,
        ],
        initialParent: parent,
      ),
    );
    if (message != null && mounted) {
      if (parent != null) setState(() => _openId = parent.id);
      _showMessage(message);
    }
  }

  Future<void> _rename(Category category) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      builder: (_) => _RenameSheet(category: category),
    );
  }

  Future<void> _toggleHidden(Category category) async {
    final l10n = context.l10n;
    final result = await ref
        .read(categoriesRepositoryProvider)
        .setHidden(category.id, hidden: !category.isHidden);
    if (!mounted) return;
    _showMessage(switch (result) {
      Ok() =>
        category.isHidden
            ? l10n.categoryShownToast(category.name)
            : l10n.categoryHiddenToast(category.name),
      Err() => l10n.errorGeneric,
    });
  }

  Future<void> _delete(Category category, {Category? parent}) async {
    final l10n = context.l10n;
    final repository = ref.read(categoriesRepositoryProvider);
    final count = await repository.operationCount(category.id);
    if (!mounted) return;
    final target = parent?.name ?? _fallbackName();
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.categoryDeleteTitle(category.name),
      message: l10n.categoryDeleteBody(count, target),
      confirmLabel: l10n.categoryDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final result = await repository.delete(category.id);
    if (!mounted) return;
    _showMessage(switch (result) {
      Ok() => l10n.categoryDeleted,
      Err() => l10n.errorGeneric,
    });
  }

  String _fallbackName() =>
      (ref.read(categoryGroupsProvider(_kind)).value ?? const [])
          .where((g) => g.category.isFallback)
          .firstOrNull
          ?.category
          .name ??
      '';

  /// Actions d'une sous-catégorie (appui sur sa pilule).
  Future<void> _subActions(Category sub, Category parent) async {
    final l10n = context.l10n;
    final action = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  sub.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            for (final (key, label, icon, enabled) in [
              (
                'rename',
                l10n.categoryRename,
                AppIcons.pencilSimple,
                sub.canRename,
              ),
              (
                'hide',
                sub.isHidden ? l10n.categoryShow : l10n.categoryHide,
                sub.isHidden ? AppIcons.eye : AppIcons.eyeSlash,
                sub.canHide,
              ),
              ('delete', l10n.categoryDelete, AppIcons.trash, sub.canDelete),
            ])
              if (enabled)
                ListTile(
                  leading: Icon(icon, size: 20),
                  title: Text(label),
                  onTap: () => Navigator.of(sheetContext).pop(key),
                ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'rename':
        await _rename(sub);
      case 'hide':
        await _toggleHidden(sub);
      case 'delete':
        await _delete(sub, parent: parent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final groups = ref.watch(categoryGroupsProvider(_kind)).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoriesTitle),
        actions: [
          IconButton(
            tooltip: l10n.categoriesNew,
            icon: const Icon(AppIcons.plusBold, size: 20),
            onPressed: _create,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        children: [
          SegmentedChoice(
            options: [
              (CategoryKind.expense, l10n.txFilterExpenseSection),
              (CategoryKind.income, l10n.txFilterIncomeSection),
            ],
            selected: _kind,
            onChanged: (kind) => setState(() {
              _kind = kind;
              _openId = null;
            }),
          ),
          const SizedBox(height: 22),
          for (final group in groups)
            _CategoryTile(
              group: group,
              open: group.category.id == _openId,
              onToggle: () => setState(
                () => _openId = group.category.id == _openId
                    ? null
                    : group.category.id,
              ),
              onAddSub: () => _create(parent: group.category),
              onSubTap: (sub) => _subActions(sub, group.category),
              onRename: () => _rename(group.category),
              onToggleHidden: () => _toggleHidden(group.category),
              onDelete: () => _delete(group.category),
            ),
          const SizedBox(height: 22),
          Text(
            l10n.categoriesFootnote,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: colors.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.group,
    required this.open,
    required this.onToggle,
    required this.onAddSub,
    required this.onSubTap,
    required this.onRename,
    required this.onToggleHidden,
    required this.onDelete,
  });

  final CategoryGroup group;
  final bool open;
  final VoidCallback onToggle;
  final VoidCallback onAddSub;
  final ValueChanged<Category> onSubTap;
  final VoidCallback onRename;
  final VoidCallback onToggleHidden;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final category = group.category;

    Widget badge(String text, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );

    final header = InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          spacing: 12,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.chip,
              ),
              child: Icon(
                categoryIcon(category.iconKey),
                size: 18,
                color: colors.ink,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (category.isCustom)
                        badge(
                          l10n.categoryCustom,
                          colors.primarySoft,
                          colors.onPrimarySoft,
                        ),
                      if (category.isHidden)
                        badge(
                          l10n.categoryHidden,
                          colors.chip,
                          colors.inkSecondary,
                        ),
                    ],
                  ),
                  Text(
                    l10n.categorySubCount(group.children.length),
                    style: TextStyle(fontSize: 12.5, color: colors.inkTertiary),
                  ),
                ],
              ),
            ),
            Icon(
              open ? AppIcons.caretDownBold : AppIcons.caretRight,
              size: 14,
              color: colors.inkTertiary,
            ),
          ],
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            expanded: open,
            child: category.isHidden
                ? Opacity(opacity: 0.55, child: header)
                : header,
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.only(left: 50, bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final sub in group.children)
                        Opacity(
                          opacity: sub.isHidden ? 0.55 : 1,
                          child: ChoicePill(
                            label: sub.name,
                            selected: false,
                            height: 34,
                            onTap: () => onSubTap(sub),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: onAddSub,
                        icon: const Icon(AppIcons.plusBold, size: 14),
                        label: Text(l10n.categoryAddSub),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          foregroundColor: colors.primary,
                          backgroundColor: Colors.transparent,
                          side: BorderSide(color: colors.inkTertiary),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 4,
                    children: [
                      if (category.canRename)
                        _ActionLink(
                          icon: AppIcons.pencilSimple,
                          label: l10n.categoryRename,
                          onPressed: onRename,
                        ),
                      if (category.canHide)
                        _ActionLink(
                          icon: category.isHidden
                              ? AppIcons.eye
                              : AppIcons.eyeSlash,
                          label: category.isHidden
                              ? l10n.categoryShow
                              : l10n.categoryHide,
                          onPressed: onToggleHidden,
                        ),
                      if (category.canDelete)
                        _ActionLink(
                          icon: AppIcons.trash,
                          label: l10n.categoryDelete,
                          onPressed: onDelete,
                          color: colors.negative,
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionLink extends StatelessWidget {
  const _ActionLink({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 16),
    label: Text(label),
    style: TextButton.styleFrom(
      foregroundColor: color ?? context.colors.ink,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      minimumSize: const Size(0, 44),
    ),
  );
}

/// Feuille « Nouvelle catégorie / sous-catégorie ». Retourne le message de
/// confirmation, ou `null` si fermée sans créer.
class _CategorySheet extends ConsumerStatefulWidget {
  const _CategorySheet({
    required this.kind,
    required this.parents,
    this.initialParent,
  });

  final CategoryKind kind;
  final List<Category> parents;
  final Category? initialParent;

  @override
  ConsumerState<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<_CategorySheet> {
  final _name = TextEditingController();
  late Category? _parent = widget.initialParent;
  String _icon = CategoryDraft.defaultIcon;
  Set<CategoryFieldError> _errors = const {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() => _errors = const {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    setState(() => _saving = true);
    final result = await ref
        .read(categoriesRepositoryProvider)
        .create(
          CategoryDraft(
            kind: widget.kind,
            name: _name.text,
            parentId: _parent?.id,
            iconKey: _icon,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok(:final value):
        final parent = _parent;
        Navigator.of(context).pop(
          parent == null
              ? l10n.categoryCreated(value.name)
              : l10n.categorySubCreated(value.name, parent.name),
        );
      case Err(failure: ValidationFailure<CategoryFieldError>(:final errors)):
        setState(() => _errors = errors);
      case Err():
        setState(() => _errors = const {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final parent = _parent;
    final canSubmit =
        !_saving && CategoryDraft.normalize(_name.text).isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              Text(
                parent == null ? l10n.categoriesNew : l10n.categoriesNewSub,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _Field(
                label: l10n.categoryName,
                child: TextField(
                  controller: _name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l10n.categoryNameHint,
                    errorText: _errorText(l10n, _errors),
                  ),
                ),
              ),
              _Field(
                label: l10n.categoryAttachTo,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoicePill(
                      label: l10n.categoryNoParent,
                      selected: parent == null,
                      onTap: () => setState(() => _parent = null),
                    ),
                    for (final candidate in widget.parents)
                      ChoicePill(
                        label: candidate.name,
                        icon: categoryIcon(candidate.iconKey),
                        selected: candidate.id == parent?.id,
                        onTap: () => setState(() => _parent = candidate),
                      ),
                  ],
                ),
              ),
              if (parent == null)
                _Field(
                  label: l10n.categoryIcon,
                  child: GridView.count(
                    crossAxisCount: 6,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    mainAxisExtent: 46,
                    children: [
                      for (final key in CategoryDraft.icons)
                        _IconChoice(
                          icon: categoryIcon(key),
                          label: l10n.categoryIconLabel(
                            key.replaceAll('-', '_'),
                          ),
                          selected: key == _icon,
                          onTap: () => setState(() => _icon = key),
                        ),
                    ],
                  ),
                ),
              FilledButton(
                onPressed: canSubmit ? _submit : null,
                child: Text(
                  parent == null
                      ? l10n.categoryCreate
                      : l10n.categoryAddTo(parent.name),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RenameSheet extends ConsumerStatefulWidget {
  const _RenameSheet({required this.category});

  final Category category;

  @override
  ConsumerState<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends ConsumerState<_RenameSheet> {
  late final _name = TextEditingController(text: widget.category.name);
  Set<CategoryFieldError> _errors = const {};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final result = await ref
        .read(categoriesRepositoryProvider)
        .rename(widget.category.id, _name.text);
    if (!mounted) return;
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
      case Err(failure: ValidationFailure<CategoryFieldError>(:final errors)):
        setState(() => _errors = errors);
      case Err():
        Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              Text(
                l10n.categoryRenameTitle(widget.category.name),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextField(
                controller: _name,
                autofocus: true,
                onChanged: (_) => setState(() => _errors = const {}),
                decoration: InputDecoration(
                  errorText: _errorText(l10n, _errors),
                ),
              ),
              FilledButton(onPressed: _submit, child: Text(l10n.accountSave)),
            ],
          ),
        ),
      ),
    );
  }
}

String? _errorText(AppLocalizations l10n, Set<CategoryFieldError> errors) {
  if (errors.contains(CategoryFieldError.nameTaken)) {
    return l10n.categoryErrorNameTaken;
  }
  if (errors.contains(CategoryFieldError.nameTooLong)) {
    return l10n.categoryErrorNameTooLong;
  }
  if (errors.contains(CategoryFieldError.nameMissing)) {
    return l10n.categoryErrorNameMissing;
  }
  return null;
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 8,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: context.colors.inkSecondary,
        ),
      ),
      child,
    ],
  );
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: selected
          ? BorderSide(color: colors.primary, width: 2)
          : BorderSide(color: colors.line),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.primarySoft : colors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Icon(icon, size: 20, color: colors.ink),
        ),
      ),
    );
  }
}
