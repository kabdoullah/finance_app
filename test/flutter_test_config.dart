import 'dart:async';

import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Configuration commune de `flutter test` : préférences en mémoire (pas de
/// plateforme Android dans les tests), vidées avant chaque fichier.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  await testMain();
}
