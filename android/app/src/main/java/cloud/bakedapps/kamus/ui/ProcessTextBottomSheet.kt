package cloud.bakedapps.kamus.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.OpenInNew
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import cloud.bakedapps.kamus.data.api.TdkApiClient
import cloud.bakedapps.kamus.data.db.DictionaryStore
import cloud.bakedapps.kamus.data.models.WordResult
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProcessTextBottomSheet(
    initialWord: String,
    store: DictionaryStore,
    onSpeak: (String) -> Unit,
    onOpenInApp: (String) -> Unit,
    onDismiss: () -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()

    var currentWord by remember { mutableStateOf(initialWord) }
    var results by remember { mutableStateOf<List<WordResult>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var isFavorite by remember { mutableStateOf(false) }

    fun executeSearch(word: String) {
        val trimmed = word.trim().trim(',', '.', ';', ':', '!', '?', '"', '“', '”', '(', ')')
        if (trimmed.isEmpty()) {
            errorMessage = "Aranacak bir kelime seçilmedi."
            isLoading = false
            return
        }
        currentWord = trimmed
        isLoading = true
        errorMessage = null

        scope.launch {
            // 1. Önce yerel SQLite önbellek
            val cached = store.cachedResponse(trimmed)
            if (cached != null) {
                val parsed = TdkApiClient.parseJson(cached)
                if (parsed.isNotEmpty()) {
                    results = parsed
                    isLoading = false
                    isFavorite = store.isFavorite(trimmed)
                }
            }

            // 2. TDK API üzerinden canlı arama
            try {
                val response = TdkApiClient.searchWord(trimmed)
                results = response.results
                isLoading = false
                if (response.results.isEmpty()) {
                    errorMessage = "\"$trimmed\" sözlükte bulunamadı."
                } else {
                    store.save(trimmed, response.rawJson)
                    isFavorite = store.isFavorite(trimmed)
                }
            } catch (e: Exception) {
                isLoading = false
                if (results.isEmpty()) {
                    errorMessage = "Kelime aranamadı veya çevrimdışısınız."
                }
            }
        }
    }

    LaunchedEffect(initialWord) {
        executeSearch(initialWord)
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .padding(bottom = 24.dp)
        ) {
            // Üst Bar: Kâmus Başlığı, Uygulamada Aç, Kapat
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Kâmus",
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.primary
                )

                Spacer(modifier = Modifier.weight(1f))

                if (results.isNotEmpty()) {
                    TextButton(onClick = {
                        onOpenInApp(currentWord)
                        onDismiss()
                    }) {
                        Icon(
                            imageVector = Icons.Default.OpenInNew,
                            contentDescription = null,
                            modifier = Modifier.padding(end = 4.dp)
                        )
                        Text("Uygulamada Aç")
                    }
                }

                IconButton(onClick = {
                    scope.launch { sheetState.hide() }.invokeOnCompletion { onDismiss() }
                }) {
                    Icon(imageVector = Icons.Default.Close, contentDescription = "Kapat")
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // İçerik Alanı
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                contentAlignment = Alignment.Center
            ) {
                if (isLoading && results.isEmpty()) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.padding(vertical = 40.dp)
                    ) {
                        CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = "\"$currentWord\" aranıyor…",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                        )
                    }
                } else if (errorMessage != null && results.isEmpty()) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.padding(vertical = 40.dp)
                    ) {
                        Text(
                            text = errorMessage ?: "",
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.75f)
                        )
                    }
                } else if (results.isNotEmpty()) {
                    Column {
                        results.forEach { wordResult ->
                            WordDetailCard(
                                wordResult = wordResult,
                                isFavorite = isFavorite,
                                onToggleFavorite = {
                                    scope.launch {
                                        isFavorite = store.toggleFavorite(currentWord)
                                    }
                                },
                                onSpeak = onSpeak,
                                onSelectWord = { nextWord ->
                                    executeSearch(nextWord)
                                }
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                        }
                    }
                }
            }
        }
    }
}
