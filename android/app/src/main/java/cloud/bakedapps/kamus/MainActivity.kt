package cloud.bakedapps.kamus

import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Sparkles
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import cloud.bakedapps.kamus.data.db.DictionaryStore
import cloud.bakedapps.kamus.data.tts.TurkishTextToSpeech
import cloud.bakedapps.kamus.theme.KamusTheme
import cloud.bakedapps.kamus.ui.FavoritesScreen
import cloud.bakedapps.kamus.ui.HistoryScreen
import cloud.bakedapps.kamus.ui.HomeSearchScreen
import cloud.bakedapps.kamus.ui.WordOfTheDayScreen

class MainActivity : ComponentActivity() {
    private lateinit var store: DictionaryStore
    private var tts: TurkishTextToSpeech? = null
    private var clipboardWordState = mutableStateOf<String?>(null)
    private var selectedTabState = mutableIntStateOf(0)
    private var initialSearchQuery = mutableStateOf<String?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        store = DictionaryStore.getInstance(this)
        tts = TurkishTextToSpeech(this)

        handleIntent(intent)

        setContent {
            KamusTheme {
                MainAppScreen(
                    store = store,
                    selectedTab = selectedTabState.intValue,
                    onTabSelected = { selectedTabState.intValue = it },
                    clipboardWord = clipboardWordState.value,
                    onDismissClipboard = { clipboardWordState.value = null },
                    onSpeak = { word -> tts?.speak(word) }
                )
            }
        }
    }

    override fun onResume() {
        super.onResume()
        checkClipboard()
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        intent?.let { handleIntent(it) }
    }

    private fun handleIntent(intent: Intent) {
        val query = intent.getStringExtra("SEARCH_QUERY")
            ?: intent.data?.getQueryParameter("q")

        if (!query.isNullOrBlank()) {
            initialSearchQuery.value = query.trim()
            selectedTabState.intValue = 0
        }
    }

    private fun checkClipboard() {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
        val clip = clipboard?.primaryClip
        if (clip != null && clip.itemCount > 0) {
            val text = clip.getItemAt(0).text?.toString()?.trim()
            if (!text.isNullOrBlank() && text.length <= 35 && !text.contains('\n')) {
                val words = text.split("\\s+".toRegex())
                if (words.size <= 2) {
                    val clean = text.trim(',', '.', ';', ':', '!', '?', '"', '“', '”', '(', ')')
                    if (clean.length >= 2 && clean != clipboardWordState.value) {
                        clipboardWordState.value = clean
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        tts?.shutdown()
        tts = null
    }
}

enum class NavigationItem(val title: String, val icon: ImageVector) {
    SEARCH("Ara", Icons.Default.Search),
    WORD_OF_DAY("Günün Kelimesi", Icons.Default.Sparkles),
    FAVORITES("Favoriler", Icons.Default.Bookmark),
    HISTORY("Geçmiş", Icons.Default.History)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainAppScreen(
    store: DictionaryStore,
    selectedTab: Int,
    onTabSelected: (Int) -> Unit,
    clipboardWord: String?,
    onDismissClipboard: () -> Unit,
    onSpeak: (String) -> Unit
) {
    val items = NavigationItem.values()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = when (selectedTab) {
                            0 -> "Kâmus"
                            1 -> "Günün Kelimesi"
                            2 -> "Favoriler"
                            3 -> "Arama Geçmişi"
                            else -> "Kâmus"
                        },
                        style = MaterialTheme.typography.titleLarge
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                    titleContentColor = MaterialTheme.colorScheme.primary
                )
            )
        },
        bottomBar = {
            NavigationBar(
                containerColor = MaterialTheme.colorScheme.surface
            ) {
                items.forEachIndexed { index, item ->
                    NavigationBarItem(
                        icon = { Icon(item.icon, contentDescription = item.title) },
                        label = { Text(item.title) },
                        selected = selectedTab == index,
                        onClick = { onTabSelected(index) }
                    )
                }
            }
        }
    ) { innerPadding ->
        when (selectedTab) {
            0 -> HomeSearchScreen(
                store = store,
                clipboardWord = clipboardWord,
                onDismissClipboard = onDismissClipboard,
                onSpeak = onSpeak,
                onNavigateToTab = onTabSelected,
                modifier = Modifier.padding(innerPadding)
            )
            1 -> WordOfTheDayScreen(
                store = store,
                onSpeak = onSpeak,
                onSelectWord = { word ->
                    onTabSelected(0)
                },
                modifier = Modifier.padding(innerPadding)
            )
            2 -> FavoritesScreen(
                store = store,
                onSelectWord = { word ->
                    onTabSelected(0)
                },
                modifier = Modifier.padding(innerPadding)
            )
            3 -> HistoryScreen(
                store = store,
                onSelectWord = { word ->
                    onTabSelected(0)
                },
                modifier = Modifier.padding(innerPadding)
            )
        }
    }
}
