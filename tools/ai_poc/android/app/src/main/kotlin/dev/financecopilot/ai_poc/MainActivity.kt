package dev.financecopilot.ai_poc

import android.content.Intent
import android.os.Bundle
import android.os.SystemClock
import android.speech.RecognitionListener
import android.speech.RecognitionSupport
import android.speech.RecognitionSupportCallback
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * POC : reconnaissance vocale garantie SUR L'APPAREIL
 * (SpeechRecognizer.createOnDeviceSpeechRecognizer, Android 12+) : l'audio
 * ne quitte pas le téléphone.
 */
class MainActivity : FlutterActivity() {
    private var recognizer: SpeechRecognizer? = null

    private fun frenchIntent() = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
        putExtra(RecognizerIntent.EXTRA_LANGUAGE, "fr-FR")
        putExtra(
            RecognizerIntent.EXTRA_LANGUAGE_MODEL,
            RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
        )
        putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "poc/ondevice_stt")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "support" -> support(result)
                    "download" -> {
                        SpeechRecognizer.createOnDeviceSpeechRecognizer(this)
                            .triggerModelDownload(frenchIntent())
                        result.success(true)
                    }
                    "listen" -> listen(result)
                    else -> result.notImplemented()
                }
            }
    }

    /** Disponibilité et langues hors ligne (installées, prises en charge). */
    private fun support(result: MethodChannel.Result) {
        if (!SpeechRecognizer.isOnDeviceRecognitionAvailable(this)) {
            result.success(mapOf("available" to false))
            return
        }
        val checker = SpeechRecognizer.createOnDeviceSpeechRecognizer(this)
        checker.checkRecognitionSupport(
            frenchIntent(),
            mainExecutor,
            object : RecognitionSupportCallback {
                override fun onSupportResult(support: RecognitionSupport) {
                    checker.destroy()
                    result.success(
                        mapOf(
                            "available" to true,
                            "installed" to support.installedOnDeviceLanguages,
                            "pending" to support.pendingOnDeviceLanguages,
                            "supported" to support.supportedOnDeviceLanguages,
                        ),
                    )
                }

                override fun onError(error: Int) {
                    checker.destroy()
                    result.success(mapOf("available" to true, "error" to error))
                }
            },
        )
    }

    /** Écoute une phrase ; délai mesuré depuis la fin de la parole. */
    private fun listen(result: MethodChannel.Result) {
        recognizer?.destroy()
        val sr = SpeechRecognizer.createOnDeviceSpeechRecognizer(this)
        recognizer = sr
        var endOfSpeech = 0L
        var replied = false
        fun reply(map: Map<String, Any?>) {
            if (replied) return
            replied = true
            sr.destroy()
            recognizer = null
            result.success(map)
        }
        sr.setRecognitionListener(object : RecognitionListener {
            override fun onEndOfSpeech() {
                endOfSpeech = SystemClock.elapsedRealtime()
            }

            override fun onResults(results: Bundle) {
                val text = results
                    .getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    ?.firstOrNull()
                val ms = if (endOfSpeech == 0L) -1L
                else SystemClock.elapsedRealtime() - endOfSpeech
                reply(mapOf("text" to text, "msAfterSpeech" to ms))
            }

            override fun onError(error: Int) {
                reply(mapOf("error" to error))
            }

            override fun onReadyForSpeech(params: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onPartialResults(partialResults: Bundle?) {}
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
        sr.startListening(frenchIntent())
    }

    override fun onDestroy() {
        recognizer?.destroy()
        super.onDestroy()
    }
}
