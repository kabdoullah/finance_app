import AVFoundation
import Flutter
import Network
import Speech
import UIKit
import os

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let device = DeviceChannel()
  private let speech = SpeechChannel()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let messenger = engineBridge.pluginRegistry.registrar(forPlugin: "FinaoNative")?
      .messenger()
    {
      device.register(messenger)
      speech.register(messenger)
    }
  }
}

/// Canal `finance_app/device` : ce qu'il faut pour décider si l'IA peut tourner
/// sur ce téléphone (même contrat que MainActivity sur Android).
final class DeviceChannel {
  private let monitor = NWPathMonitor()
  private var expensive = false

  init() {
    monitor.pathUpdateHandler = { [weak self] path in
      self?.expensive = path.isExpensive
    }
    monitor.start(queue: DispatchQueue(label: "finao.network"))
  }

  func register(_ messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "finance_app/device", binaryMessenger: messenger)
      .setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "info": result(self?.info())
        // Notifications gérées par flutter_local_notifications ; écran
        // masqué dans les applications récentes : pas d'équivalent iOS.
        case "requestNotifications": result(true)
        case "setSecure": result(nil)
        default: result(FlutterMethodNotImplemented)
        }
      }
  }

  private func info() -> [String: Any] {
    var free: Int64 = 0
    if let values = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(
      forKeys: [.volumeAvailableCapacityForImportantUsageKey])
    {
      free = values.volumeAvailableCapacityForImportantUsage ?? 0
    }
    return [
      // Version majeure d'iOS (Android : niveau d'API).
      "sdk": ProcessInfo.processInfo.operatingSystemVersion.majorVersion,
      "is64Bit": true,
      "totalRam": Int64(ProcessInfo.processInfo.physicalMemory),
      // Mémoire que l'application peut encore utiliser avant qu'iOS ne la
      // ferme : plus juste qu'un chiffre global pour charger Gemma.
      "availableRam": Int64(os_proc_available_memory()),
      "freeStorage": free,
      "metered": expensive,
    ]
  }
}

/// Canal `finance_app/speech` : dictée en français STRICTEMENT sur l'appareil
/// (requiresOnDeviceRecognition), jamais via les serveurs d'Apple. Mêmes
/// événements et mêmes codes d'erreur que SpeechRecognizer sur Android.
final class SpeechChannel: NSObject, FlutterStreamHandler {
  // Codes SpeechRecognizer.ERROR_* d'Android, attendus côté Dart.
  private static let errorSpeechTimeout = 6
  private static let errorNoMatch = 7
  private static let errorPermission = 9
  private static let errorLanguageUnavailable = 13
  private static let errorOther = 5

  /// Fin de phrase : silence après la dernière parole.
  private static let silence: TimeInterval = 1.5
  /// Rien dit du tout : abandon.
  private static let noSpeech: TimeInterval = 6

  private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
  private let engine = AVAudioEngine()
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var events: FlutterEventSink?
  private var silenceTimer: Timer?
  private var lastText = ""
  private var finished = false

  func register(_ messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "finance_app/speech", binaryMessenger: messenger)
      .setMethodCallHandler { [weak self] call, result in
        guard let self else { return }
        switch call.method {
        case "status": result(self.status())
        // iOS ne laisse pas une application installer une langue : l'écran
        // montre les étapes dans Réglages.
        case "download": result(nil)
        case "requestPermission": self.requestPermission(result)
        case "start":
          self.start()
          result(nil)
        case "stop":
          self.stop()
          result(nil)
        case "cancel":
          self.cancel()
          result(nil)
        default: result(FlutterMethodNotImplemented)
        }
      }
    FlutterEventChannel(name: "finance_app/speech/events", binaryMessenger: messenger)
      .setStreamHandler(self)
  }

  func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink)
    -> FlutterError?
  {
    events = eventSink
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    events = nil
    return nil
  }

  private func status() -> String {
    guard let recognizer else { return "unsupported" }
    // Français hors connexion absent : à activer dans Réglages › Clavier.
    return recognizer.supportsOnDeviceRecognition ? "ready" : "missingLanguage"
  }

  private func requestPermission(_ result: @escaping FlutterResult) {
    SFSpeechRecognizer.requestAuthorization { status in
      guard status == .authorized else {
        DispatchQueue.main.async { result(false) }
        return
      }
      SpeechChannel.requestMicrophone { granted in
        DispatchQueue.main.async { result(granted) }
      }
    }
  }

  /// Autorisation du micro (AVAudioApplication depuis iOS 17).
  private static var microphoneGranted: Bool {
    if #available(iOS 17.0, *) {
      return AVAudioApplication.shared.recordPermission == .granted
    }
    return AVAudioSession.sharedInstance().recordPermission == .granted
  }

  private static func requestMicrophone(_ done: @escaping (Bool) -> Void) {
    if #available(iOS 17.0, *) {
      AVAudioApplication.requestRecordPermission(completionHandler: done)
    } else {
      AVAudioSession.sharedInstance().requestRecordPermission(done)
    }
  }

  private func send(_ event: [String: Any]) {
    DispatchQueue.main.async { [weak self] in self?.events?(event) }
  }

  private func fail(_ code: Int) {
    guard !finished else { return }
    finished = true
    teardown()
    send(["type": "error", "code": code])
  }

  private func start() {
    cancel()
    finished = false
    lastText = ""
    guard SFSpeechRecognizer.authorizationStatus() == .authorized,
      SpeechChannel.microphoneGranted
    else {
      fail(Self.errorPermission)
      return
    }
    guard let recognizer, recognizer.supportsOnDeviceRecognition else {
      fail(Self.errorLanguageUnavailable)
      return
    }
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.requiresOnDeviceRecognition = true
    request.shouldReportPartialResults = true
    self.request = request
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.record, mode: .measurement, options: .duckOthers)
      try session.setActive(true, options: .notifyOthersOnDeactivation)
      let input = engine.inputNode
      let format = input.outputFormat(forBus: 0)
      input.installTap(onBus: 0, bufferSize: 1024, format: format) {
        [weak self] buffer, _ in
        request.append(buffer)
        self?.sendLevel(buffer)
      }
      engine.prepare()
      try engine.start()
    } catch {
      fail(Self.errorOther)
      return
    }
    task = recognizer.recognitionTask(with: request) { [weak self] result, error in
      guard let self else { return }
      if let result {
        let text = result.bestTranscription.formattedString
        if result.isFinal {
          self.finish(text)
          return
        }
        if !text.isEmpty, text != self.lastText {
          self.lastText = text
          self.send(["type": "partial", "text": text])
          self.armSilence(Self.silence)
        }
      } else if error != nil {
        // Arrêt sans résultat final : texte déjà entendu, sinon rien entendu.
        if self.lastText.isEmpty {
          self.fail(Self.errorNoMatch)
        } else {
          self.finish(self.lastText)
        }
      }
    }
    send(["type": "ready"])
    armSilence(Self.noSpeech)
  }

  /// Après un silence, termine la phrase (ou abandonne si rien n'a été dit).
  private func armSilence(_ delay: TimeInterval) {
    DispatchQueue.main.async { [weak self] in
      self?.silenceTimer?.invalidate()
      self?.silenceTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) {
        [weak self] _ in
        guard let self else { return }
        if self.lastText.isEmpty {
          self.fail(Self.errorSpeechTimeout)
        } else {
          self.stop()
        }
      }
    }
  }

  private func finish(_ text: String) {
    guard !finished else { return }
    finished = true
    teardown()
    send(["type": "final", "text": text])
  }

  /// Volume du micro sur l'échelle d'Android (environ −2 à 10).
  private func sendLevel(_ buffer: AVAudioPCMBuffer) {
    guard let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return }
    var sum: Float = 0
    for i in 0..<Int(buffer.frameLength) { sum += samples[i] * samples[i] }
    let rms = sqrt(sum / Float(buffer.frameLength))
    let db = max(-60, 20 * log10(max(rms, 1e-7)))
    send(["type": "level", "value": Double((db + 60) / 60 * 12 - 2)])
  }

  /// Fin de la parole : le résultat final arrive ensuite.
  private func stop() {
    DispatchQueue.main.async { [weak self] in self?.silenceTimer?.invalidate() }
    if engine.isRunning {
      engine.stop()
      engine.inputNode.removeTap(onBus: 0)
    }
    request?.endAudio()
  }

  private func cancel() {
    finished = true
    teardown()
  }

  private func teardown() {
    DispatchQueue.main.async { [weak self] in self?.silenceTimer?.invalidate() }
    if engine.isRunning {
      engine.stop()
      engine.inputNode.removeTap(onBus: 0)
    }
    task?.cancel()
    task = nil
    request = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
}
