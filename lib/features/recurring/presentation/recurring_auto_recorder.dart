import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import 'recurring_providers.dart';

/// Enregistre les échéances des modèles « sans confirmation » à l'ouverture
/// de l'application et à chaque retour au premier plan (pas de service en
/// arrière-plan). Les échéances manquées sont rattrapées à leur date.
class RecurringAutoRecorder extends ConsumerStatefulWidget {
  const RecurringAutoRecorder({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<RecurringAutoRecorder> createState() =>
      _RecurringAutoRecorderState();
}

class _RecurringAutoRecorderState extends ConsumerState<RecurringAutoRecorder> {
  late final AppLifecycleListener _lifecycle;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _run);
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_running || !mounted) return;
    _running = true;
    try {
      final count = await ref
          .read(recurringRepositoryProvider)
          .recordAutomatic();
      if (count > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.recurringAutoRecorded(count))),
        );
      }
    } on Object catch (error, stackTrace) {
      // Gestionnaire d'erreurs central : l'échéance reste en attente.
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    } finally {
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
