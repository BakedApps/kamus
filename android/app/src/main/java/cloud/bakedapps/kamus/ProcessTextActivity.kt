package cloud.bakedapps.kamus

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import cloud.bakedapps.kamus.data.db.DictionaryStore
import cloud.bakedapps.kamus.data.tts.TurkishTextToSpeech
import cloud.bakedapps.kamus.theme.KamusTheme
import cloud.bakedapps.kamus.ui.ProcessTextBottomSheet

class ProcessTextActivity : ComponentActivity() {
    private lateinit var store: DictionaryStore
    private var tts: TurkishTextToSpeech? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        store = DictionaryStore.getInstance(this)
        tts = TurkishTextToSpeech(this)

        val selectedText = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
            ?: intent.getStringExtra(Intent.EXTRA_TEXT)
            ?: ""

        val cleanedWord = cleanWord(selectedText)

        setContent {
            KamusTheme {
                ProcessTextBottomSheet(
                    initialWord = cleanedWord,
                    store = store,
                    onSpeak = { word -> tts?.speak(word) },
                    onOpenInApp = { word ->
                        val mainIntent = Intent(this, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                            putExtra("SEARCH_QUERY", word)
                        }
                        startActivity(mainIntent)
                        finish()
                    },
                    onDismiss = {
                        finish()
                    }
                )
            }
        }
    }

    private fun cleanWord(raw: String): String {
        val trimmed = raw.trim()
        val firstToken = trimmed.split("\\s+".toRegex()).firstOrNull() ?: trimmed
        return firstToken.trim(',', '.', ';', ':', '!', '?', '"', '“', '”', '(', ')', '[', ']')
    }

    override fun onDestroy() {
        super.onDestroy()
        tts?.shutdown()
        tts = null
    }
}
