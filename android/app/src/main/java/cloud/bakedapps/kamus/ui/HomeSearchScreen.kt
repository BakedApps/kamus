package cloud.bakedapps.kamus.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentPaste
import androidx.compose.material.icons.filled.NorthWest
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Sparkles
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import cloud.bakedapps.kamus.data.api.TdkApiClient
import cloud.bakedapps.kamus.data.db.DictionaryStore
import cloud.bakedapps.kamus.data.models.HistoryItem
import cloud.bakedapps.kamus.data.models.SearchResponse
import cloud.bakedapps.kamus.data.models.WordResult
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun HomeSearchScreen(
    store: DictionaryStore,
    clipboardWord: String?,
    onDismissClipboard: () -> Unit,
    onSpeak: (String) -> Unit,
    onNavigateToTab: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    val scope = rememberCoroutineScope()
    val focusManager = LocalFocusManager()

    var searchQuery by remember { mutableStateOf("") }
    var results by remember { mutableStateOf<List<WordResult>>(emptyList()) }
    var suggestions by remember { mutableStateOf<List<String>>(emptyList()) }
    var recentSearches by remember { mutableStateOf<List<HistoryItem>>(emptyList()) }
    var todayWord by remember { mutableStateOf<Pair<String, SearchResponse>?>(null) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var isCurrentFavorite by remember { mutableStateOf(false) }

    var searchJob by remember { mutableStateOf<Job?>(null) }
    var suggestJob by remember { mutableStateOf<Job?>(null) }

    fun refreshRecent() {
        scope.launch {
            recentSearches = store.recentSearches(limit = 15)
            todayWord = store.wordOfTheDay()
        }
    }

    LaunchedEffect(Unit) {
        refreshRecent()
    }

    fun performSearch(word: String) {
        val trimmed = word.trim()
        if (trimmed.isEmpty()) return

        searchQuery = trimmed
        suggestions = emptyList()
        focusManager.clearFocus()
        isLoading = true
        errorMessage = null

        searchJob?.cancel()
        searchJob = scope.launch {
            // Önce yerel önbellek kontrolü
            val cached = store.cachedResponse(trimmed)
            if (cached != null) {
                val parsed = TdkApiClient.parseJson(cached)
                if (parsed.isNotEmpty()) {
                    results = parsed
                    isLoading = false
                    store.touch(trimmed)
                    isCurrentFavorite = store.isFavorite(trimmed)
                    refreshRecent()
                }
            }

            // Canlı TDK API
            try {
                val response = TdkApiClient.searchWord(trimmed)
                results = response.results
                isLoading = false
                if (response.results.isEmpty()) {
                    errorMessage = "\"$trimmed\" kelimesi sözlükte bulunamadı."
                } else {
                    store.save(trimmed, response.rawJson)
                    isCurrentFavorite = store.isFavorite(trimmed)
                    refreshRecent()
                }
            } catch (e: Exception) {
                isLoading = false
                if (results.isEmpty()) {
                    errorMessage = "Arama yapılamadı. İnternet bağlantınızı kontrol edin."
                }
            }
        }
    }

    fun updateSuggestions(query: String) {
        suggestJob?.cancel()
        if (query.isBlank()) {
            suggestions = emptyList()
            return
        }
        suggestJob = scope.launch {
            delay(120)
            suggestions = store.autocomplete(query, limit = 8)
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp)
            .verticalScroll(rememberScrollState())
    ) {
        Spacer(modifier = Modifier.height(16.dp))

        // Pano Algılama Bildirimi
        AnimatedVisibility(
            visible = clipboardWord != null,
            enter = fadeIn(),
            exit = fadeOut()
        ) {
            if (clipboardWord != null) {
                Card(
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f)
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 12.dp)
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.ContentPaste,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary
                        )
                        Spacer(modifier = Modifier.width(10.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "Panodaki kelimeyi ara:",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                            )
                            Text(
                                text = clipboardWord,
                                style = MaterialTheme.typography.titleLarge.copy(fontSize = 16.sp),
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                        Button(
                            onClick = {
                                onDismissClipboard()
                                performSearch(clipboardWord)
                            },
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text("Ara")
                        }
                        IconButton(onClick = onDismissClipboard) {
                            Icon(imageVector = Icons.Default.Close, contentDescription = "Kapat")
                        }
                    }
                }
            }
        }

        // Arama Kutusu
        OutlinedTextField(
            value = searchQuery,
            onValueChange = {
                searchQuery = it
                if (it.isBlank()) {
                    results = emptyList()
                    suggestions = emptyList()
                    errorMessage = null
                } else if (results.isEmpty()) {
                    updateSuggestions(it)
                }
            },
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text("Kelime ara…") },
            leadingIcon = {
                Icon(imageVector = Icons.Default.Search, contentDescription = null)
            },
            trailingIcon = {
                if (searchQuery.isNotEmpty()) {
                    IconButton(onClick = {
                        searchQuery = ""
                        results = emptyList()
                        suggestions = emptyList()
                        errorMessage = null
                    }) {
                        Icon(imageVector = Icons.Default.Clear, contentDescription = "Temizle")
                    }
                }
            },
            shape = RoundedCornerShape(12.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedContainerColor = MaterialTheme.colorScheme.surface,
                unfocusedContainerColor = MaterialTheme.colorScheme.surface
            ),
            singleLine = true,
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
            keyboardActions = KeyboardActions(onSearch = { performSearch(searchQuery) })
        )

        // Canlı Öneri Listesi
        if (suggestions.isNotEmpty() && results.isEmpty()) {
            Card(
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 4.dp)
            ) {
                Column {
                    suggestions.forEachIndexed { idx, item ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { performSearch(item) }
                                .padding(horizontal = 14.dp, vertical = 10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.Search,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp),
                                tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                            )
                            Spacer(modifier = Modifier.width(10.dp))
                            Text(
                                text = item,
                                style = MaterialTheme.typography.bodyLarge,
                                modifier = Modifier.weight(1f)
                            )
                            Icon(
                                imageVector = Icons.Default.NorthWest,
                                contentDescription = null,
                                modifier = Modifier.size(14.dp),
                                tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
                            )
                        }
                        if (idx < suggestions.lastIndex) {
                            HorizontalDivider(modifier = Modifier.padding(start = 40.dp))
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // İçerik: Boşken Feed | Doluyken Arama Sonuçları
        if (searchQuery.isBlank() && results.isEmpty()) {
            // Günün Kelimesi Kartı
            todayWord?.let { (word, response) ->
                val first = response.results.firstOrNull()
                val meaning = first?.anlamlarListe?.firstOrNull()
                if (first != null && meaning != null) {
                    Card(
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onNavigateToTab(1) }
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    imageVector = Icons.Default.Sparkles,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.secondary,
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = "GÜNÜN KELİMESİ",
                                    style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                                    color = MaterialTheme.colorScheme.secondary
                                )
                            }
                            Spacer(modifier = Modifier.height(8.dp))
                            Row(verticalAlignment = Alignment.Baseline) {
                                Text(
                                    text = first.madde,
                                    style = MaterialTheme.typography.headlineMedium,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                                if (first.lisan.isNotBlank()) {
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = first.lisan,
                                        style = MaterialTheme.typography.bodyMedium.copy(fontStyle = FontStyle.Italic),
                                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                                    )
                                }
                            }
                            Spacer(modifier = Modifier.height(6.dp))
                            Text(
                                text = meaning.anlam,
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.8f),
                                maxLines = 2,
                                overflow = TextOverflow.Ellipsis
                            )
                        }
                    }
                    Spacer(modifier = Modifier.height(20.dp))
                }
            }

            // Son Aramalar Çipleri
            if (recentSearches.isNotEmpty()) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "SON ARAMALAR",
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                    Spacer(modifier = Modifier.weight(1f))
                    TextButton(onClick = { onNavigateToTab(3) }) {
                        Text("Tümünü Gör")
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    recentSearches.take(12).forEach { item ->
                        Surface(
                            shape = CircleShape,
                            color = MaterialTheme.colorScheme.surface,
                            shadowElevation = 1.dp,
                            modifier = Modifier.clickable { performSearch(item.word) }
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                if (item.isFavorite) {
                                    Icon(
                                        imageVector = Icons.Default.Bookmark,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.secondary,
                                        modifier = Modifier.size(12.dp)
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                }
                                Text(
                                    text = item.word,
                                    style = MaterialTheme.typography.bodyMedium
                                )
                            }
                        }
                    }
                }
            }
        } else if (isLoading) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 40.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = "Aranıyor…",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
            }
        } else if (errorMessage != null) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 40.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(
                    imageVector = Icons.Default.Search,
                    contentDescription = null,
                    modifier = Modifier.size(48.dp),
                    tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
                )
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = errorMessage ?: "",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
            }
        } else if (results.isNotEmpty()) {
            Column(modifier = Modifier.padding(bottom = 24.dp)) {
                results.forEach { wordResult ->
                    WordDetailCard(
                        wordResult = wordResult,
                        isFavorite = isCurrentFavorite,
                        onToggleFavorite = {
                            scope.launch {
                                isCurrentFavorite = store.toggleFavorite(wordResult.madde)
                                refreshRecent()
                            }
                        },
                        onSpeak = onSpeak,
                        onSelectWord = { nextWord ->
                            performSearch(nextWord)
                        }
                    )
                    Spacer(modifier = Modifier.height(14.dp))
                }
            }
        }

        Spacer(modifier = Modifier.height(30.dp))
    }
}
