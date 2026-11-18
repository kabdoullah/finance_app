part of 'main.dart';

// 2e série : A. conversation ouverte ; B. audio natif de Gemma 4 ;
// C. reconnaissance hors ligne d'Android (canal Kotlin).

const _onDeviceStt = MethodChannel('poc/ondevice_stt');

/// Consigne et outils raccourcis (A) : mesure le poids de leur lecture.
const _shortInstruction =
    'Assistant finances (FCFA). Appelle toujours un outil, ne calcule pas. '
    'Réponds en français, en une phrase.';

final _shortTools = [
  for (final t in _PocPageState._tools)
    Tool(
      name: t.name,
      description: t.description.split('.').first,
      parameters: t.parameters,
    ),
];

extension _Series2 on _PocPageState {
  // ---------------------------------------------------------------------------
  // A. Conversation ouverte : 5 questions de suite dans la même conversation.

  Future<void> _sessionTest() => _guarded('session', () async {
    final picks = [0, 7, 11, 14, 17].map((i) => toolCases[i]).toList();
    final model = await FlutterEdgeAi.getActiveModel(
      maxTokens: 4096,
      preferredBackend: PreferredBackend.cpu,
    );
    final out = <String, Object?>{};
    try {
      for (final (label, instruction, tools) in [
        ('complete', _PocPageState._assistantInstruction, _PocPageState._tools),
        ('courte', _shortInstruction, _shortTools),
      ]) {
        final chat = await model.openChat(
          temperature: 0,
          tools: tools,
          supportsFunctionCalls: true,
          systemInstruction: instruction,
        );
        final turns = <Map<String, Object?>>[];
        for (final (i, c) in picks.indexed) {
          await chat.addQueryChunk(
            Message.text(text: c.question, isUser: true),
          );
          final sw = Stopwatch()..start();
          int? callMs;
          FunctionCallResponse? first;
          final answer = StringBuffer();
          await for (final r in chat.generateChatResponseWithTools(
            onToolCall: (call) {
              callMs ??= sw.elapsedMilliseconds;
              first ??= call;
              return _PocPageState._mockTool(call);
            },
            maxToolTurns: 3,
          )) {
            if (r is TextResponse) answer.write(r.token);
          }
          final call = first;
          final correct = call != null && _PocPageState._matches(c, call);
          _say(
            'Session $label q${i + 1} : outil en ${callMs ?? '—'} ms, '
            'total ${sw.elapsedMilliseconds} ms ${correct ? '✓' : '✗'}',
          );
          turns.add({
            'question': c.question,
            'toolMs': callMs,
            'totalMs': sw.elapsedMilliseconds,
            'correct': correct,
            'answer': answer.toString().trim(),
          });
        }
        out[label] = turns;
        await _save('session', out);
      }
    } finally {
      await model.close();
    }
  });

  // ---------------------------------------------------------------------------
  // Micro : enregistrement avec arrêt automatique en fin de phrase.

  /// PCM 16 kHz mono 16 bits, arrêté après 0,8 s de silence suivant la
  /// parole (10 s au plus). Renvoie aussi l'instant de fin de parole.
  Future<(Uint8List, Stopwatch)?> _recordPhrase() async {
    final recorder = AudioRecorder();
    if (!await recorder.hasPermission()) {
      _say('Micro refusé');
      return null;
    }
    final stream = await recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
    final pcm = BytesBuilder();
    final noise = <double>[];
    final done = Completer<void>();
    final clock = Stopwatch()..start();
    var speaking = false;
    var lastVoiceMs = 0;
    final sub = stream.listen((chunk) {
      pcm.add(chunk);
      final rms = _rms(chunk);
      if (noise.length < 5) {
        noise.add(rms);
        return;
      }
      final floor = noise.reduce((a, b) => a > b ? a : b);
      final threshold = floor * 2.5 > 400 ? floor * 2.5 : 400;
      final now = clock.elapsedMilliseconds;
      if (rms > threshold) {
        speaking = true;
        lastVoiceMs = now;
      } else if (speaking && now - lastVoiceMs > 800) {
        if (!done.isCompleted) done.complete();
      }
      if (now > 10000 && !done.isCompleted) done.complete();
    });
    await done.future;
    final endOfSpeech = Stopwatch()..start();
    await recorder.stop();
    await sub.cancel();
    await recorder.dispose();
    return (pcm.takeBytes(), endOfSpeech);
  }

  static double _rms(Uint8List chunk) {
    final data = ByteData.sublistView(chunk);
    final n = data.lengthInBytes ~/ 2;
    if (n == 0) return 0;
    var sum = 0.0;
    for (var i = 0; i < n; i++) {
      final s = data.getInt16(i * 2, Endian.little);
      sum += s * s;
    }
    return math.sqrt(sum / n);
  }

  /// En-tête WAV (PCM 16 bits, 16 kHz, mono) devant les échantillons.
  static Uint8List _wav(Uint8List pcm) {
    final header = ByteData(44);
    void ascii(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        header.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    header.setUint32(4, 36 + pcm.length, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    header
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little)
      ..setUint16(22, 1, Endian.little)
      ..setUint32(24, 16000, Endian.little)
      ..setUint32(28, 32000, Endian.little)
      ..setUint16(32, 2, Endian.little)
      ..setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    header.setUint32(40, pcm.length, Endian.little);
    return Uint8List.fromList([...header.buffer.asUint8List(), ...pcm]);
  }

  // ---------------------------------------------------------------------------
  // B. Audio natif de Gemma 4 : transcription puis JSON direct.

  Future<void> _gemmaVoice() => _guarded('gemma_voice', () async {
    final phrase = voicePhrases[_gemmaPhrase % voicePhrases.length];
    var model = _audioModel;
    if (model == null) {
      _say('Chargement de Gemma avec audio…');
      final (loaded, peakMb) = await _withPeakRss(() async {
        final sw = Stopwatch()..start();
        final m = await FlutterEdgeAi.getActiveModel(
          maxTokens: 2048,
          preferredBackend: PreferredBackend.cpu,
          supportAudio: true,
        );
        return (m, sw.elapsedMilliseconds);
      });
      model = loaded.$1;
      _audioModel = model;
      _say('Gemma audio chargé en ${loaded.$2} ms, RAM max $peakMb Mo');
      await _save('gemma_audio_load', {'ms': loaded.$2, 'peakRssMb': peakMb});
    }
    _say('Phrase ${_gemmaPhrase + 1}/8 — dis : « ${phrase.text} »');
    final recorded = await _recordPhrase();
    if (recorded == null) return;
    final (pcm, sinceEnd) = recorded;
    final wav = _wav(pcm);

    // B1. Transcription.
    final chat = await model.openChat(temperature: 0, supportAudio: true);
    await chat.addQueryChunk(
      Message.withAudio(
        text:
            'Transcris mot pour mot, en français, ce que dit cet '
            'enregistrement. Réponds seulement par la transcription.',
        audioBytes: wav,
        isUser: true,
      ),
    );
    final r1 = await chat.generateChatResponse();
    final transcript = r1 is TextResponse ? r1.token.trim() : '$r1';
    final transcriptMs = sinceEnd.elapsedMilliseconds;
    _say('Gemma transcrit (${transcriptMs}ms) : « $transcript »');

    // B2. JSON directement depuis l'audio.
    final jsonSw = Stopwatch()..start();
    String raw;
    try {
      final jsonChat = await model.openChat(
        temperature: 0,
        supportAudio: true,
        systemInstruction: _PocPageState._entryInstruction,
        responseFormat: ResponseFormat.jsonSchema(_PocPageState._entrySchema),
      );
      await jsonChat.addQueryChunk(
        Message.withAudio(
          text: 'Saisie dictée.',
          audioBytes: wav,
          isUser: true,
        ),
      );
      final r2 = await jsonChat.generateChatResponse();
      raw = r2 is TextResponse ? r2.token : '$r2';
    } on Object catch (e) {
      raw = 'ERREUR $e';
    }
    final jsonMs = jsonSw.elapsedMilliseconds;
    final keyOk = _keyFieldsOk(phrase, raw);
    _say('Gemma JSON (${jsonMs}ms) ${keyOk ? '✓' : '✗'} : $raw');

    final list = (_report['gemma_voice'] as List<Object?>?) ?? <Object?>[];
    await _save('gemma_voice', [
      ...list,
      {
        'phrase': phrase.text,
        'audioSeconds': pcm.length / 32000,
        'transcript': transcript,
        'transcriptMsAfterSpeech': transcriptMs,
        'json': raw,
        'jsonMs': jsonMs,
        'keyFieldsOk': keyOk,
      },
    ]);
    _gemmaPhrase++;
  });

  /// Montant, catégorie et compte justes (critère validé).
  bool _keyFieldsOk(VoicePhrase phrase, String raw) {
    Map<String, Object?> parsed;
    try {
      parsed = (jsonDecode(raw) as Map).cast<String, Object?>();
    } on Object {
      return false;
    }
    Object? value(String key) => parsed[key] == 'none' ? null : parsed[key];
    return ['amount', 'category', 'account'].every((key) {
      final expected = phrase.expected[key];
      return expected == null
          ? value(key) == null
          : _PocPageState._same(expected, value(key));
    });
  }

  // ---------------------------------------------------------------------------
  // C. Reconnaissance hors ligne d'Android.

  Future<void> _androidSupport() => _guarded('android_support', () async {
    final r = await _onDeviceStt.invokeMapMethod<String, Object?>('support');
    _say('Reconnaissance Android hors ligne : $r');
    await _save('android_support', r);
  });

  Future<void> _androidDownload() => _guarded('android_download', () async {
    await _onDeviceStt.invokeMethod<bool>('download');
    _say('Installation du français demandée à Android.');
  });

  Future<void> _androidVoice() => _guarded('android_voice', () async {
    // Le micro est demandé une fois via record (même permission).
    final recorder = AudioRecorder();
    final allowed = await recorder.hasPermission();
    await recorder.dispose();
    if (!allowed) {
      _say('Micro refusé');
      return;
    }
    final phrase = voicePhrases[_androidPhrase % voicePhrases.length];
    _say('Phrase ${_androidPhrase + 1}/8 — dis : « ${phrase.text} »');
    final r = await _onDeviceStt.invokeMapMethod<String, Object?>('listen');
    _say('Android (${r?['msAfterSpeech']} ms) : « ${r?['text'] ?? r} »');
    final list = (_report['android_voice'] as List<Object?>?) ?? <Object?>[];
    await _save('android_voice', [
      ...list,
      {'phrase': phrase.text, ...?r},
    ]);
    _androidPhrase++;
  });
}
