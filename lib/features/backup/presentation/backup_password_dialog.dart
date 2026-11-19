import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../l10n/l10n.dart';
import '../data/backup_file.dart';

/// Demande le mot de passe d'une sauvegarde : choisi et confirmé avec
/// avertissement ([create]), ou simplement saisi (restauration). `null` si
/// annulé. Le mot de passe n'est jamais enregistré.
Future<String?> showBackupPasswordDialog(
  BuildContext context, {
  required bool create,
}) => showDialog<String>(
  context: context,
  builder: (context) => _PasswordDialog(create: create),
);

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.create});

  final bool create;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _visible = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    final password = _password.text;
    if (widget.create) {
      if (password.length < BackupFile.minPasswordLength) {
        setState(() => _error = l10n.bkPasswordTooShort);
        return;
      }
      if (password != _confirm.text) {
        setState(() => _error = l10n.bkPasswordMismatch);
        return;
      }
    } else if (password.isEmpty) {
      return;
    }
    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    Widget field(TextEditingController controller, String label) => TextField(
      controller: controller,
      obscureText: !_visible,
      autocorrect: false,
      enableSuggestions: false,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(labelText: label),
    );
    return AlertDialog(
      title: Text(l10n.bkPasswordTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            if (widget.create)
              Text(
                l10n.bkPasswordWarning,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: colors.inkSecondary,
                ),
              ),
            field(_password, l10n.bkPassword),
            if (widget.create) field(_confirm, l10n.bkPasswordConfirm),
            Row(
              children: [
                Expanded(
                  child: _error == null
                      ? const SizedBox.shrink()
                      : Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.negative,
                          ),
                        ),
                ),
                IconButton(
                  tooltip: l10n.bkPasswordShow,
                  onPressed: () => setState(() => _visible = !_visible),
                  icon: Icon(
                    _visible ? AppIcons.eyeSlash : AppIcons.eye,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.bkCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.create ? l10n.bkSave : l10n.bkContinue),
        ),
      ],
    );
  }
}
