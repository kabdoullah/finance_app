// POC de faisabilité : Gemma 4 E2B (LiteRT-LM) et reconnaissance vocale
// hors ligne sur le téléphone de test. Application jetable, séparée de
// l'application principale. Toutes les données sont fictives.
//
// Résultats : journal Android (préfixe « POC: ») et poc_report.json dans le
// dossier de l'application (adb shell run-as … cat app_flutter/poc_report.json).

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';
import 'package:flutter_edge_ai_speech/flutter_edge_ai_speech.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'test_cases.dart';

/// Révision épinglée par la documentation de flutter_edge_ai.
const _modelUrl =
    'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/'
    'resolve/b3ca0d2f076785a8f4b2219ddbd2bdb99954eae1/gemma-4-E2B-it.litertlm';
const _sttModelUrl =
    'https://huggingface.co/litert-community/whisper-tiny/resolve/main/'
    'whisper_tiny_30s_f32.tflite';
const _sttTokenizerUrl =
    'https://huggingface.co/openai/whisper-tiny/resolve/main/tokenizer.json';

/// Configurations comparées.
enum RunConfig {
  cpu('CPU', PreferredBackend.cpu, null),
  gpu16('GPU fp16', PreferredBackend.gpu, ActivationDataType.float16),
  gpu32('GPU fp32', PreferredBackend.gpu, ActivationDataType.float32);

  const RunConfig(this.label, this.backend, this.activation);

  final String label;
  final PreferredBackend backend;
  final ActivationDataType? activation;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterEdgeAi.initialize(
    inferenceEngines: const [LiteRtLmEngine()],
    sttBackends: [LiteRtSttBackend()],
  );
  runApp(const MaterialApp(home: PocPage()));
}

class PocPage extends StatefulWidget {
  const PocPage({super.key});

  @override
  State<PocPage> createState() => _PocPageState();
}

class _PocPageState extends State<PocPage> {
  final _report = <String, Object?>{};
  final _log = <String>[];
  bool _busy = false;
  int? _progress;
  RunConfig _config = RunConfig.cpu;

  // ---------------------------------------------------------------------------
  // Utilitaires : journal, rapport, mémoire.

  void _say(String line) {
    debugPrint('POC: $line');
    setState(() => _log.insert(0, line));
  }

  Future<void> _save(String key, Object? value) async {
    _report[key] = value;
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/poc_report.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(_report));
    debugPrint('POC_JSON $key: ${jsonEncode(value)}');
  }

  /// Mémoire résidente maximale (Mo) pendant [action].
  Future<(T, int)> _withPeakRss<T>(Future<T> Function() action) async {
    var peak = ProcessInfo.currentRss;
    final timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final rss = ProcessInfo.currentRss;
      if (rss > peak) peak = rss;
    });
    try {
      final result = await action();
      return (result, peak ~/ (1024 * 1024));
    } finally {
      timer.cancel();
    }
  }

  Future<void> _guarded(String name, Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (e, s) {
      _say('ÉCHEC $name : $e');
      debugPrint('POC_ERROR $name: $e\n$s');
      await _save('error_$name', '$e');
    } finally {
      setState(() {
        _busy = false;
        _progress = null;
      });
    }
  }

  Future<InferenceModel> _load(RunConfig config) =>
      FlutterEdgeAi.getActiveModel(
        maxTokens: 2048,
        preferredBackend: config.backend,
        activationDataType: config.activation,
      );

  // ---------------------------------------------------------------------------
  // 1. Téléchargement du modèle.

  Future<void> _download() => _guarded('download', () async {
    final sw = Stopwatch()..start();
    _say('Téléchargement de Gemma 4 E2B…');
    await FlutterEdgeAi.installModel(
          modelType: ModelType.gemma4,
          fileType: ModelFileType.litertlm,
        )
        .fromNetwork(_modelUrl, foreground: true)
        .withProgress((p) => setState(() => _progress = p))
        .install();
    final storage = await FlutterEdgeAi.getStorageInfo();
    _say('Modèle installé en ${sw.elapsed.inSeconds} s');
    await _save('download', {
      'seconds': sw.elapsed.inSeconds,
      'storage': storage.toString(),
    });
  });

  // ---------------------------------------------------------------------------
  // 2. Performances : chargement, premier mot, vitesse, mémoire.

  static const _benchPrompt =
      "Explique en quatre phrases simples, en français, ce qu'est un budget "
      'mensuel et pourquoi il aide à mieux gérer son argent.';

  Future<void> _bench() => _guarded('bench', () async {
    final results = <Map<String, Object?>>[];
    for (final config in RunConfig.values) {
      _say('Performances ${config.label}…');
      try {
        final (
          (loadMs, backend, ttftMs, tokens, genMs, text),
          peakMb,
        ) = await _withPeakRss(() async {
          final load = Stopwatch()..start();
          final model = await _load(config);
          final loadMs = load.elapsedMilliseconds;
          final backend = model.activeBackend;
          try {
            final chat = await model.openChat(temperature: 0.2);
            await chat.addQueryChunk(
              Message.text(text: _benchPrompt, isUser: true),
            );
            final gen = Stopwatch()..start();
            int? ttft;
            var tokens = 0;
            final buffer = StringBuffer();
            await for (final r in chat.generateChatResponseAsync()) {
              if (r is TextResponse) {
                ttft ??= gen.elapsedMilliseconds;
                tokens++;
                buffer.write(r.token);
              }
            }
            return (
              loadMs,
              backend,
              ttft,
              tokens,
              gen.elapsedMilliseconds,
              buffer.toString(),
            );
          } finally {
            await model.close();
          }
        });
        final decodeMs = genMs - (ttftMs ?? 0);
        final perSecond = decodeMs <= 0 ? 0 : tokens * 1000 / decodeMs;
        _say(
          '${config.label} (${backend?.name}) : chargement ${loadMs}ms, '
          '1er mot ${ttftMs}ms, ${perSecond.toStringAsFixed(1)} jetons/s, '
          'RAM max $peakMb Mo',
        );
        results.add({
          'config': config.label,
          'activeBackend': backend?.name,
          'loadMs': loadMs,
          'ttftMs': ttftMs,
          'tokens': tokens,
          'tokensPerSecond': double.parse(perSecond.toStringAsFixed(1)),
          'peakRssMb': peakMb,
          'answer': text,
        });
      } on Object catch (e) {
        _say('${config.label} : échec ($e)');
        results.add({'config': config.label, 'error': '$e'});
      }
      await _save('bench', results);
    }
  });

  // ---------------------------------------------------------------------------
  // 3. Appels d'outils (le modèle choisit l'outil, il ne calcule rien).

  static final _tools = [
    const Tool(
      name: 'get_spending',
      description:
          "Total des dépenses de l'utilisateur sur une période, "
          'éventuellement pour une catégorie.',
      parameters: {
        'type': 'object',
        'properties': {
          'category': {
            'type': 'string',
            'enum': expenseCategories,
            'description': _categoryHints,
          },
          'period': {
            'type': 'string',
            'enum': ['today', 'this_week', 'this_month', 'last_month'],
          },
        },
        'required': ['period'],
      },
    ),
    const Tool(
      name: 'get_budget_status',
      description:
          'État des budgets du mois : limite, dépensé, reste. Sans '
          'catégorie : tous les budgets.',
      parameters: {
        'type': 'object',
        'properties': {
          'category': {'type': 'string', 'enum': expenseCategories},
        },
      },
    ),
    const Tool(
      name: 'get_balance',
      description: "Solde d'un compte, ou de tous les comptes sans argument.",
      parameters: {
        'type': 'object',
        'properties': {
          'account': {'type': 'string', 'enum': accounts},
        },
      },
    ),
    const Tool(
      name: 'get_forecast',
      description: 'Solde prévu dans 7, 30 ou 90 jours.',
      parameters: {
        'type': 'object',
        'properties': {
          'days': {
            'type': 'integer',
            'enum': [7, 30, 90],
          },
        },
        'required': ['days'],
      },
    ),
    const Tool(
      name: 'simulate_purchase',
      description:
          'Indique si un achat est possible sans mettre le solde à '
          'découvert. Prix en FCFA.',
      parameters: {
        'type': 'object',
        'properties': {
          'label': {'type': 'string'},
          'price': {'type': 'integer'},
        },
        'required': ['price'],
      },
    ),
  ];

  static const _categoryHints =
      'Transport : taxi, wôrô-wôrô, gbaka, carburant. Alimentation : '
      'marché, restaurant, garba, nourriture. Factures : électricité CIE, '
      'eau, internet, crédit téléphone. Famille : envoi au village.';

  static const _assistantInstruction =
      "Tu es l'assistant d'une application de finances personnelles en "
      "Côte d'Ivoire (montants en FCFA). Tu ne calcules jamais toi-même : "
      'pour toute question sur les dépenses, budgets, soldes, prévisions ou '
      "achats, appelle l'outil adapté. Réponds en français, brièvement.";

  /// Résultats fictifs des outils, pour juger la réponse finale.
  static Map<String, dynamic> _mockTool(FunctionCallResponse call) =>
      switch (call.name) {
        'get_spending' => {'total': 48000, 'currency': 'FCFA'},
        'get_budget_status' => {
          'limit': 45000,
          'spent': 48000,
          'remaining': -3000,
        },
        'get_balance' => {'balance': 35000, 'currency': 'FCFA'},
        'get_forecast' => {'balance': 112000, 'low': 98000, 'high': 128000},
        'simulate_purchase' => {'verdict': 'tight', 'lowest_balance': 42000},
        _ => {'error': 'unknown tool'},
      };

  Future<void> _toolsTest() => _guarded('tools', () async {
    final results = <Map<String, Object?>>[];
    var ok = 0;
    final model = await _load(_config);
    try {
      for (final (i, c) in toolCases.indexed) {
        final chat = await model.openChat(
          temperature: 0,
          tools: _tools,
          supportsFunctionCalls: true,
          systemInstruction: _assistantInstruction,
        );
        await chat.addQueryChunk(Message.text(text: c.question, isUser: true));
        final sw = Stopwatch()..start();
        FunctionCallResponse? call;
        final text = StringBuffer();
        await for (final r in chat.generateChatResponseAsync()) {
          switch (r) {
            case FunctionCallResponse():
              call = r;
            case ParallelFunctionCallResponse(:final calls):
              call = calls.isEmpty ? null : calls.first;
            case TextResponse(:final token):
              text.write(token);
            case ThinkingResponse():
              break;
          }
          if (call != null) break;
        }
        final correct = call != null && _matches(c, call);
        if (correct) ok++;
        _say(
          '${i + 1}/${toolCases.length} ${correct ? '✓' : '✗'} '
          '${call?.name} ${call?.args}',
        );
        results.add({
          'question': c.question,
          'expected': {'tool': c.tool, 'args': c.args},
          'got': call == null
              ? {'text': text.toString()}
              : {'tool': call.name, 'args': call.args},
          'correct': correct,
          'ms': sw.elapsedMilliseconds,
        });
      }
      // Réponse complète (outil fictif) pour juger le français.
      final answers = <Map<String, String>>[];
      for (final c in toolCases.take(3)) {
        final chat = await model.openChat(
          temperature: 0.2,
          tools: _tools,
          supportsFunctionCalls: true,
          systemInstruction: _assistantInstruction,
        );
        await chat.addQueryChunk(Message.text(text: c.question, isUser: true));
        final buffer = StringBuffer();
        await for (final r in chat.generateChatResponseWithTools(
          onToolCall: _mockTool,
          maxToolTurns: 3,
        )) {
          if (r is TextResponse) buffer.write(r.token);
        }
        answers.add({'question': c.question, 'answer': buffer.toString()});
        _say('Réponse : ${buffer.toString().trim()}');
      }
      final score = ok * 100 ~/ toolCases.length;
      _say('Outils (${_config.label}) : $ok/${toolCases.length} ($score %)');
      await _save('tools_${_config.name}', {
        'score': score,
        'cases': results,
        'answers': answers,
      });
    } finally {
      await model.close();
    }
  });

  static String _norm(Object? v) => '$v'
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâ]'), 'a')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[îï]'), 'i')
      .trim();

  static bool _same(Object? expected, Object? got) {
    if (expected is num) return num.tryParse('$got') == expected;
    return _norm(expected) == _norm(got);
  }

  static bool _matches(ToolCase c, FunctionCallResponse call) =>
      call.name == c.tool &&
      c.args.entries.every((e) => _same(e.value, call.args[e.key]));

  // ---------------------------------------------------------------------------
  // 4. Saisie rapide → JSON structuré.

  /// Codes stables (sans espace ni accent) : le décodage contraint de
  /// LiteRT-LM échoue sur « Orange Money » ou « Argent reçu ».
  static const _categoryCodes = {
    'Alimentation': 'food',
    'Transport': 'transport',
    'Logement': 'housing',
    'Factures': 'bills',
    'Loisirs': 'leisure',
    'Santé': 'health',
    'Famille': 'family',
    'Tontine': 'tontine',
    'Éducation': 'education',
    'Habillement': 'clothing',
    'Autre': 'other',
    'Salaire': 'salary',
    'Ventes': 'sales',
    'Argent reçu': 'money_received',
    'Autre revenu': 'other_income',
  };
  static const _accountCodes = {
    'Espèces': 'cash',
    'Wave': 'wave',
    'Orange Money': 'orange_money',
    'MTN MoMo': 'mtn_momo',
    'Ecobank': 'ecobank',
  };

  static final _entrySchema = <String, Object?>{
    'type': 'object',
    'properties': {
      'kind': {
        'type': 'string',
        'enum': ['expense', 'income', 'transfer'],
      },
      'amount': {'type': 'integer'},
      'category': {
        'type': 'string',
        'enum': [..._categoryCodes.values, 'none'],
      },
      'account': {
        'type': 'string',
        'enum': [..._accountCodes.values, 'none'],
      },
      'date': {
        'type': 'string',
        'enum': ['today', 'yesterday'],
      },
    },
    'required': ['kind', 'amount', 'category', 'account', 'date'],
    'additionalProperties': false,
  };

  static const _entryInstruction =
      "Tu analyses une saisie rapide d'opération en FCFA (Côte d'Ivoire) et "
      'tu renvoies uniquement le JSON demandé.\n'
      'kind : expense pour un achat ou un paiement (taxi, marché, loyer, '
      "facture…) ; income pour de l'argent reçu (salaire, vente, argent "
      'envoyé par quelqu\'un) ; transfer UNIQUEMENT si la personne déplace '
      'de l\'argent entre deux de ses comptes (« de X vers Y »).\n'
      'amount : entier en FCFA (« mille » = ×1000, « 75 000 » = 75000).\n'
      'date : yesterday si « hier », sinon today.\n'
      'category (dépenses) : food (marché, restaurant, garba), transport '
      '(taxi, wôrô, gbaka, carburant), housing (loyer), bills (électricité '
      'CIE, eau, internet, crédit téléphone), leisure (cinéma, sorties), '
      'health (pharmacie), family (envoi au village), tontine, education '
      '(scolarité), clothing (pagne, vêtements), other. (revenus) : salary, '
      'sales, money_received, other_income. none pour un transfert.\n'
      'account : cash (espèces), wave, orange_money (orange money, orange), '
      'mtn_momo (mtn), ecobank ; none si aucun compte n\'est cité ; pour un '
      'transfert, le compte débité.\n'
      'Exemples : « essence 5000 wave » → {"kind":"expense","amount":5000,'
      '"category":"transport","account":"wave","date":"today"} ; '
      '« paie 250 mille hier ecobank » → {"kind":"income","amount":250000,'
      '"category":"salary","account":"ecobank","date":"yesterday"}.';

  Future<void> _entriesTest() => _guarded('entries', () async {
    final results = <Map<String, Object?>>[];
    var good = 0;
    var total = 0;
    final model = await _load(_config);
    try {
      for (final (i, c) in entryCases.indexed) {
        final chat = await model.openChat(
          temperature: 0,
          systemInstruction: _entryInstruction,
          responseFormat: ResponseFormat.jsonSchema(_entrySchema),
        );
        await chat.addQueryChunk(Message.text(text: c.text, isUser: true));
        final sw = Stopwatch()..start();
        final response = await chat.generateChatResponse();
        final raw = response is TextResponse ? response.token : '$response';
        Map<String, Object?> parsed;
        try {
          parsed = (jsonDecode(raw) as Map).cast<String, Object?>();
        } on Object {
          parsed = const {};
        }
        var caseGood = 0;
        for (final MapEntry(:key, :value) in c.expected.entries) {
          var got = parsed[key];
          if (got == 'none') got = null;
          final expected = switch (key) {
            'category' => _categoryCodes[value] ?? value,
            'account' => _accountCodes[value] ?? value,
            _ => value,
          };
          final same = expected == null ? got == null : _same(expected, got);
          if (same) caseGood++;
        }
        good += caseGood;
        total += c.expected.length;
        _say('${i + 1}/${entryCases.length} $caseGood/5 « ${c.text} » → $raw');
        results.add({
          'text': c.text,
          'expected': c.expected,
          'raw': raw,
          'fieldsCorrect': caseGood,
          'ms': sw.elapsedMilliseconds,
        });
      }
      final score = good * 100 ~/ total;
      _say('Saisie JSON (${_config.label}) : $good/$total champs ($score %)');
      await _save('entries_${_config.name}', {
        'score': score,
        'cases': results,
      });
    } finally {
      await model.close();
    }
  });

  // ---------------------------------------------------------------------------
  // 5. Voix : 5 s enregistrées puis transcrites par Whisper tiny (français).

  Future<void> _speech() => _guarded('speech', () async {
    if (!FlutterEdgeAi.hasActiveStt()) {
      _say('Installation de Whisper tiny…');
      await FlutterEdgeAi.installStt()
          .modelFromNetwork(_sttModelUrl)
          .tokenizerFromNetwork(_sttTokenizerUrl)
          .ofType(SttModelType.whisper)
          .install();
    }
    final recorder = AudioRecorder();
    if (!await recorder.hasPermission()) {
      _say('Micro refusé');
      return;
    }
    _say('Parle pendant 5 secondes…');
    final pcm = BytesBuilder();
    final stream = await recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
    final sub = stream.listen(pcm.add);
    await Future<void>.delayed(const Duration(seconds: 5));
    await recorder.stop();
    await sub.cancel();
    await recorder.dispose();

    final stt = await FlutterEdgeAi.getActiveStt(language: 'fr');
    try {
      final sw = Stopwatch()..start();
      final text = await stt.transcribe(
        Uint8List.fromList(pcm.takeBytes()),
        language: 'fr',
      );
      _say('Transcription (${sw.elapsedMilliseconds} ms) : « $text »');
      final list = (_report['speech'] as List<Object?>?) ?? <Object?>[];
      await _save('speech', [
        ...list,
        {'text': text, 'ms': sw.elapsedMilliseconds},
      ]);
    } finally {
      await stt.close();
    }
  });

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    return Scaffold(
      appBar: AppBar(title: const Text('POC IA')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (progress != null) Text('Téléchargement : $progress %'),
          const SizedBox(height: 8),
          SegmentedButton<RunConfig>(
            segments: [
              for (final c in RunConfig.values)
                ButtonSegment(value: c, label: Text(c.label)),
            ],
            selected: {_config},
            onSelectionChanged: (s) => setState(() => _config = s.first),
          ),
          const SizedBox(height: 8),
          for (final (label, action) in [
            ('1. Télécharger le modèle', _download),
            ('2. Performances (CPU / GPU)', _bench),
            ("3. Appels d'outils", _toolsTest),
            ('4. Saisie → JSON', _entriesTest),
            ('5. Voix (5 s, Whisper)', _speech),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton(
                onPressed: _busy ? null : action,
                child: Text(label),
              ),
            ),
          const Divider(),
          for (final line in _log)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(line, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
