import 'package:finance_app/features/assistant/domain/assistant_reply.dart';
import 'package:finance_app/features/assistant/domain/number_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NumberCheck', () {
    test('lit les montants écrits de plusieurs façons', () {
      expect(NumberCheck.inText('35 000, 35 000, 35.000, 2500 et 34 %'), {
        35000,
        2500,
        34,
      });
    });

    test('nombres des résultats d\'outils, textes compris', () {
      expect(
        NumberCheck.inData({
          'total_fcfa': 35000,
          'date': '30 nov.',
          'details': [
            {'amount_fcfa': -3000, 'percent': 34},
          ],
        }),
        containsAll([35000, 30, 3000, 34]),
      );
    });
  });

  group('composeReply', () {
    const outcome = ToolOutcome(
      data: {'total_fcfa': 35000, 'period': 'cette semaine'},
      summary: 'Tu as dépensé 35 000 FCFA cette semaine.',
      rows: [ReplyRow('Alimentation', '17 000 FCFA', ratio: 1)],
      link: ReplyLink(ReplyLinkTarget.transactions),
    );

    test('phrase de Gemma gardée si ses nombres viennent des outils', () {
      final reply = composeReply(
        question: 'Combien cette semaine ?',
        gemmaText: 'Tu as dépensé **35 000 FCFA** cette semaine.',
        outcomes: [outcome],
        fallback: 'Je n\'ai pas compris.',
      );
      expect(reply.text, 'Tu as dépensé 35 000 FCFA cette semaine.');
      expect(reply.rows, hasLength(1));
      expect(reply.link?.target, ReplyLinkTarget.transactions);
      expect(reply.fromTools, isTrue);
    });

    test('nombre inventé : phrase de l\'application à la place', () {
      final reply = composeReply(
        question: 'Combien cette semaine ?',
        gemmaText: 'Tu as dépensé 42 000 FCFA, 20 % de plus.',
        outcomes: [outcome],
        fallback: 'Je n\'ai pas compris.',
      );
      expect(reply.text, outcome.summary);
    });

    test('nombre de la question accepté', () {
      final reply = composeReply(
        question: 'Puis-je acheter un téléphone à 150 000 ?',
        gemmaText: 'Pour 150 000 FCFA, ton solde passerait à 35 000 FCFA.',
        outcomes: [outcome],
        fallback: '',
      );
      expect(reply.text, startsWith('Pour 150 000'));
    });

    test('outil sans chiffres à montrer : phrase de l\'application', () {
      final reply = composeReply(
        question: 'Puis-je acheter un téléphone à 150 000 ?',
        gemmaText: 'Je ne peux pas te dire sans plus d\'informations.',
        outcomes: const [
          ToolOutcome(
            data: {'forecast': 'not_enough_history'},
            summary:
                'Les prévisions apparaîtront après environ deux '
                'semaines d\'opérations.',
            link: ReplyLink(ReplyLinkTarget.simulation),
          ),
        ],
        fallback: '',
      );
      expect(reply.text, startsWith('Les prévisions apparaîtront'));
      expect(reply.fromTools, isFalse);
      expect(reply.link?.target, ReplyLinkTarget.simulation);
    });

    test('sans outil : texte sans nombre gardé, sinon « pas compris »', () {
      expect(
        composeReply(
          question: 'C\'est quoi une tontine ?',
          gemmaText: 'Une tontine est une épargne collective.',
          outcomes: const [],
          fallback: 'Je n\'ai pas compris.',
        ).text,
        'Une tontine est une épargne collective.',
      );
      final invented = composeReply(
        question: 'Combien je dépense ?',
        gemmaText: 'Environ 50 000 FCFA par mois.',
        outcomes: const [],
        fallback: 'Je n\'ai pas compris.',
      );
      expect(invented.text, 'Je n\'ai pas compris.');
      expect(invented.fromTools, isFalse);
    });
  });
}
