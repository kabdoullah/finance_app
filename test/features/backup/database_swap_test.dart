import 'dart:io';

import 'package:finance_app/features/backup/data/database_swap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late File target;
  late File ready;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('swap_test');
    target = File('${dir.path}/app.sqlite')..writeAsStringSync('actuelle');
    ready = File('${dir.path}/ready.tmp')..writeAsStringSync('restaurée');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  List<String> files() =>
      dir.listSync().map((f) => f.uri.pathSegments.last).toList()..sort();

  test('remplacée, sans fichier laissé', () async {
    var closed = 0;
    String? opened;
    await replaceDatabaseFile(
      ready: ready,
      target: target,
      close: () async => closed++,
      reopen: () async => opened = target.readAsStringSync(),
    );
    expect(opened, 'restaurée');
    expect(closed, 1);
    expect(files(), ['app.sqlite']);
  });

  test(
    'échec à l\'ouverture : données d\'origine remises et rouvertes',
    () async {
      final opened = <String>[];
      await expectLater(
        replaceDatabaseFile(
          ready: ready,
          target: target,
          close: () async {},
          reopen: () async {
            final content = target.readAsStringSync();
            opened.add(content);
            if (content == 'restaurée') throw StateError('migration');
          },
        ),
        throwsStateError,
      );
      expect(opened, ['restaurée', 'actuelle']);
      expect(target.readAsStringSync(), 'actuelle');
      expect(files(), ['app.sqlite']);
    },
  );
}
