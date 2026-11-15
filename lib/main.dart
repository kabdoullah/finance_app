import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'core/errors/error_reporter.dart';

void main() {
  installGlobalErrorHandlers();
  runApp(const ProviderScope(child: FinanceApp()));
}
