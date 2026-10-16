package cloud.bakedapps.kamus.data.tts

import android.content.Context
import android.speech.tts.TextToSpeech
import java.util.Locale

class TurkishTextToSpeech(context: Context) {
    private var tts: TextToSpeech? = null
    private var isInitialized = false
    private val turkishLocale = Locale("tr", "TR")

    init {
        tts = TextToSpeech(context.applicationContext) { status ->
            if (status == TextToSpeech.SUCCESS) {
                tts?.let { engine ->
                    val result = engine.setLanguage(turkishLocale)
                    isInitialized = result != TextToSpeech.LANG_MISSING_DATA &&
                            result != TextToSpeech.LANG_NOT_SUPPORTED
                    engine.setSpeechRate(0.92f)
                }
            }
        }
    }

    fun speak(text: String) {
        val trimmed = text.trim()
        if (trimmed.isEmpty() || !isInitialized) return
        tts?.speak(trimmed, TextToSpeech.QUEUE_FLUSH, null, "kamus_speech_${System.currentTimeMillis()}")
    }

    fun stop() {
        tts?.stop()
    }

    fun shutdown() {
        tts?.stop()
        tts?.shutdown()
        tts = null
        isInitialized = false
    }
}
