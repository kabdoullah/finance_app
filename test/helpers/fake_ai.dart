import 'dart:async';

import 'package:finance_app/features/assistant/data/ai_platform.dart';
import 'package:finance_app/features/assistant/domain/ai_compatibility.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';

const gb = 1000 * 1000 * 1000;

/// Téléphone de test (par défaut : compatible, en Wi-Fi).
DeviceCapabilities fakeDevice({
  bool isIos = false,
  int osVersion = 34,
  bool is64Bit = true,
  int totalRam = 8 * gb,
  int availableRam = 4 * gb,
  int freeStorage = 20 * gb,
  bool metered = false,
}) => DeviceCapabilities(
  isIos: isIos,
  osVersion: osVersion,
  is64Bit: is64Bit,
  totalRamBytes: totalRam,
  availableRamBytes: availableRam,
  freeStorageBytes: freeStorage,
  metered: metered,
);

class FakeDeviceInfo extends DeviceInfoService {
  FakeDeviceInfo(this.device);

  DeviceCapabilities? device;

  @override
  Future<DeviceCapabilities?> read() async => device;

  @override
  Future<void> requestNotifications() async {}
}

/// Conversation de test : répond [answer] à chaque message (ou attend
/// indéfiniment si [answer] est `null`) ; avec outils, appelle d'abord
/// [toolCall] puis répond [answer].
class FakeChat implements InferenceChat {
  FakeChat(this.answer, {this.toolCall, this.tools = const []});

  final String? answer;
  final FunctionCallResponse? toolCall;
  @override
  final List<Tool> tools;
  final queries = <String>[];

  /// Résultats renvoyés par l'application pour [toolCall].
  final toolResults = <Map<String, dynamic>>[];
  bool closed = false;

  @override
  Future<void> addQueryChunk(
    Message message, [
    bool noTool = false,
    bool prefix = false,
  ]) async => queries.add(message.text);

  @override
  Future<ModelResponse> generateChatResponse() => answer == null
      ? Completer<ModelResponse>().future
      : Future.value(TextResponse(answer!));

  @override
  Stream<ModelResponse> generateChatResponseWithTools({
    required FutureOr<Map<String, dynamic>> Function(FunctionCallResponse call)
    onToolCall,
    int maxToolTurns = 8,
    bool Function()? isCancelled,
    void Function()? onMaxToolTurns,
  }) async* {
    if (toolCall case final call?) toolResults.add(await onToolCall(call));
    if (answer case final text?) yield TextResponse(text);
  }

  @override
  Future<void> clearHistory({List<Message>? replayHistory}) async {}

  @override
  Future<void> close() async => closed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeModel implements InferenceModel {
  FakeModel({this.answer, this.toolCall});

  /// Réponse de la conversation ouverte par [openChat] (JSON pour la saisie,
  /// texte pour l'assistant).
  String? answer;

  /// Outil que le faux Gemma appelle (assistant).
  FunctionCallResponse? toolCall;
  FakeChat? lastChat;
  bool closed = false;

  @override
  Future<InferenceChat> openChat({
    double? temperature,
    int? randomSeed,
    int? topK,
    double? topP,
    int tokenBuffer = 256,
    String? loraPath,
    bool? supportImage,
    bool? supportAudio,
    List<Tool> tools = const [],
    bool? supportsFunctionCalls,
    bool enableThinking = false,
    ModelType? modelType,
    ToolChoice toolChoice = ToolChoice.auto,
    int? maxFunctionBufferLength,
    String? systemInstruction,
    int? maxOutputTokens,
    ResponseFormat? responseFormat,
  }) async => lastChat = FakeChat(answer, toolCall: toolCall, tools: tools);

  @override
  Future<void> close() async => closed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGemmaRuntime extends GemmaRuntime {
  FakeGemmaRuntime({this.installed = false, FakeModel? model})
    : model = model ?? FakeModel();

  bool installed;
  bool failLoad = false;
  Completer<void>? pendingInstall;
  final FakeModel model;

  @override
  Future<bool> isInstalled() async => installed;

  @override
  Future<void> install({
    required void Function(int percent) onProgress,
    required CancelToken cancel,
  }) async {
    onProgress(40);
    final pending = pendingInstall = Completer<void>();
    unawaited(
      cancel.whenCancelled.then((_) {
        if (!pending.isCompleted) {
          pending.completeError(
            DownloadCancelledException('annulé', StackTrace.current),
          );
        }
      }),
    );
    await pending.future;
    installed = true;
  }

  @override
  Future<InferenceModel> load() async {
    if (failLoad) throw StateError('échec');
    return model;
  }

  @override
  Future<void> uninstall() async => installed = false;
}

class FakeAiPreferences implements AiPreferences {
  FakeAiPreferences({this.value = false});

  bool value;

  @override
  Future<bool> loadOnStartup() async => value;

  @override
  Future<void> setLoadOnStartup(bool value) async => this.value = value;
}
