import 'dart:io';

/// Remplace le fichier de la base [target] par [ready] sans perte :
/// la base actuelle est fermée ([close]) et mise de côté ; si la nouvelle
/// ne s'ouvre pas ([reopen] échoue, migrations comprises), l'ancienne est
/// remise en place et rouverte, puis l'erreur est relancée.
Future<void> replaceDatabaseFile({
  required File ready,
  required File target,
  required Future<void> Function() close,
  required Future<void> Function() reopen,
}) async {
  final safety = File('${target.path}.before-restore');
  await close();
  if (safety.existsSync()) safety.deleteSync();
  if (target.existsSync()) target.renameSync(safety.path);
  try {
    // Copie (et non déplacement) : le dossier temporaire peut être sur un
    // autre volume.
    await ready.copy(target.path);
    await reopen();
  } on Object {
    try {
      await close();
    } on Object {
      // La nouvelle base n'a peut-être jamais été ouverte.
    }
    if (target.existsSync()) target.deleteSync();
    if (safety.existsSync()) safety.renameSync(target.path);
    await reopen();
    rethrow;
  } finally {
    if (ready.existsSync()) ready.deleteSync();
  }
  if (safety.existsSync()) safety.deleteSync();
}
