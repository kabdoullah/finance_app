package com.example.finance_app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognitionSupport
import android.speech.RecognitionSupportCallback
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Dictée : reconnaissance vocale garantie SUR L'APPAREIL
 * (SpeechRecognizer.createOnDeviceSpeechRecognizer, Android 12+). L'audio ne
 * quitte jamais le téléphone ; sans elle, l'application propose le clavier.
 */
class MainActivity : FlutterActivity() {
    private var recognizer: SpeechRecognizer? = null
    private var events: EventChannel.EventSink? = null
    private var pendingPermission: MethodChannel.Result? = null

    private fun frenchIntent() = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
        putExtra(RecognizerIntent.EXTRA_LANGUAGE, "fr-FR")
        putExtra(
            RecognizerIntent.EXTRA_LANGUAGE_MODEL,
            RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
        )
        putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "finance_app/speech").setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> status(result)
                "download" -> download(result)
                "requestPermission" -> requestPermission(result)
                "start" -> {
                    start()
                    result.success(null)
                }
                "stop" -> {
                    recognizer?.stopListening()
                    result.success(null)
                }
                "cancel" -> {
                    releaseRecognizer()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        EventChannel(messenger, "finance_app/speech/events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                    events = sink
                }

                override fun onCancel(arguments: Any?) {
                    events = null
                }
            },
        )
    }

    /**
     * État : `unsupported` (Android < 12 ou service absent), `missingLanguage`
     * (français non installé), `downloading`, `ready` ; `unknown` quand
     * Android ne sait pas répondre (Android 12).
     */
    private fun status(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            !SpeechRecognizer.isOnDeviceRecognitionAvailable(this)
        ) {
            result.success("unsupported")
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success("unknown")
            return
        }
        val checker = SpeechRecognizer.createOnDeviceSpeechRecognizer(this)
        checker.checkRecognitionSupport(
            frenchIntent(),
            mainExecutor,
            object : RecognitionSupportCallback {
                override fun onSupportResult(support: RecognitionSupport) {
                    checker.destroy()
                    val french = { list: List<String> -> list.any { it.startsWith("fr") } }
                    result.success(
                        when {
                            french(support.installedOnDeviceLanguages) -> "ready"
                            french(support.pendingOnDeviceLanguages) -> "downloading"
                            else -> "missingLanguage"
                        },
                    )
                }

                override fun onError(error: Int) {
                    checker.destroy()
                    result.success("unknown")
                }
            },
        )
    }

    /** Demande l'installation du français (ignorée par certaines surcouches). */
    private fun download(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val sr = SpeechRecognizer.createOnDeviceSpeechRecognizer(this)
            sr.triggerModelDownload(frenchIntent())
            sr.destroy()
        }
        result.success(null)
    }

    private fun requestPermission(result: MethodChannel.Result) {
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        pendingPermission = result
        requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), REQUEST_AUDIO)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_AUDIO) {
            pendingPermission?.success(
                grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED,
            )
            pendingPermission = null
        }
    }

    /** Écoute ; les résultats partiels et finaux passent par le flux. */
    private fun start() {
        releaseRecognizer()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            events?.success(mapOf("type" to "error", "code" to -1))
            return
        }
        val sr = SpeechRecognizer.createOnDeviceSpeechRecognizer(this)
        recognizer = sr
        sr.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                events?.success(mapOf("type" to "ready"))
            }

            override fun onRmsChanged(rmsdB: Float) {
                events?.success(mapOf("type" to "level", "value" to rmsdB.toDouble()))
            }

            override fun onPartialResults(partialResults: Bundle?) {
                val text = partialResults
                    ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    ?.firstOrNull()
                if (!text.isNullOrBlank()) {
                    events?.success(mapOf("type" to "partial", "text" to text))
                }
            }

            override fun onResults(results: Bundle) {
                val text = results
                    .getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    ?.firstOrNull()
                events?.success(mapOf("type" to "final", "text" to (text ?: "")))
                releaseRecognizer()
            }

            override fun onError(error: Int) {
                events?.success(mapOf("type" to "error", "code" to error))
                releaseRecognizer()
            }

            override fun onBeginningOfSpeech() {}
            override fun onEndOfSpeech() {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
        sr.startListening(frenchIntent())
    }

    private fun releaseRecognizer() {
        recognizer?.destroy()
        recognizer = null
    }

    override fun onDestroy() {
        releaseRecognizer()
        super.onDestroy()
    }

    private companion object {
        const val REQUEST_AUDIO = 4201
    }
}
