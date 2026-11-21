import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/money/money.dart';
import 'package:finance_app/features/assistant/data/assistant_history_repository.dart';
import 'package:finance_app/features/assistant/domain/assistant_reply.dart';
import 'package:finance_app/features/quick_entry/domain/quick_entry_parser.dart';
import 'package:finance_app/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  late AppDatabase db;
  late AssistantHistoryRepository history;
  var now = testNow;

  setUp(() {
    db = newTestDatabase();
    now = testNow;
    history = AssistantHistoryRepository(db, () => now);
  });
  tearDown(() => db.close());

  final taxi = ParsedOperation(
    kind: TransactionKind.expense,
    amount: const Money(2500),
    categoryId: 'exp.transport.taxi',
    accountId: 'wave-id',
    date: DateTime(2026, 11, 15),
    description: 'Taxi',
    source: 'Taxi 2 500 avec Wave',
    uncertain: const {ParsedField.account},
  );

  test('aller-retour : questions, chiffres, lien, carte préparée', () async {
    await history.add(const UserEntry('Combien cette semaine ?'));
    now = now.add(const Duration(seconds: 1));
    await history.add(
      const ReplyEntry(
        text: 'Tu as dépensé 28 000 FCFA.',
        rows: [ReplyRow('Alimentation', '17 000 FCFA', ratio: 1)],
        link: ReplyLink(
          ReplyLinkTarget.goal,
          goalName: 'Moto',
          goalTarget: 100000,
          goalMonths: 3,
        ),
        fromTools: true,
        head: ReplyHead(
          '28 000 FCFA',
          'dépensés cette semaine',
          tone: ReplyTone.warning,
        ),
      ),
    );
    now = now.add(const Duration(seconds: 1));
    await history.add(ReplyEntry(text: 'J\'ai préparé…', prepared: [taxi]));

    final loaded = await history.load();
    expect(loaded, hasLength(3));
    expect((loaded[0] as UserEntry).text, 'Combien cette semaine ?');
    final figures = loaded[1] as ReplyEntry;
    expect(figures.rows.single.label, 'Alimentation');
    expect(figures.rows.single.ratio, 1);
    expect(figures.link?.target, ReplyLinkTarget.goal);
    expect(figures.link?.goalMonths, 3);
    expect(figures.fromTools, isTrue);
    expect(figures.head?.value, '28 000 FCFA');
    expect(figures.head?.caption, 'dépensés cette semaine');
    expect(figures.head?.tone, ReplyTone.warning);

    final card = loaded[2] as ReplyEntry;
    final op = card.prepared.single;
    expect(op.amount, const Money(2500));
    expect(op.date, DateTime(2026, 11, 15));
    expect(op.source, 'Taxi 2 500 avec Wave');
    expect(op.uncertain, {ParsedField.account});
    // En attente dans une autre session : plus enregistrable.
    expect(card.preparedState, PreparedState.unsaved);
  });

  test('carte enregistrée : état et mention conservés', () async {
    final card = await history.add(
      ReplyEntry(text: 'J\'ai préparé…', prepared: [taxi]),
    );
    await history.update(
      card.withPrepared(PreparedState.saved, note: 'Dépense enregistrée'),
    );
    final loaded = (await history.load()).single as ReplyEntry;
    expect(loaded.preparedState, PreparedState.saved);
    expect(loaded.note, 'Dépense enregistrée');
  });

  test('limite de messages, puis effacement', () async {
    for (var i = 0; i < AssistantHistoryRepository.maxMessages + 3; i++) {
      now = testNow.add(Duration(seconds: i));
      await history.add(UserEntry('question $i'));
    }
    final loaded = await history.load();
    expect(loaded, hasLength(AssistantHistoryRepository.maxMessages));
    expect((loaded.first as UserEntry).text, 'question 3');

    await history.clear();
    expect(await history.load(), isEmpty);
  });
}
