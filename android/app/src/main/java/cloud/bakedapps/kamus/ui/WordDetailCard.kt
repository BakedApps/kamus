package cloud.bakedapps.kamus.ui

import android.content.Intent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.VolumeUp
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import cloud.bakedapps.kamus.data.models.Meaning
import cloud.bakedapps.kamus.data.models.WordResult

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun WordDetailCard(
    wordResult: WordResult,
    isFavorite: Boolean,
    onToggleFavorite: () -> Unit,
    onSpeak: (String) -> Unit,
    onSelectWord: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current

    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(18.dp)) {
            // Header: Kelime Başlığı, Telaffuz, Favori, Paylaş
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                SelectionContainer(modifier = Modifier.weight(1f)) {
                    Column {
                        Text(
                            text = wordResult.madde,
                            style = MaterialTheme.typography.headlineMedium,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        if (wordResult.lisan.isNotBlank()) {
                            Text(
                                text = wordResult.lisan,
                                style = MaterialTheme.typography.bodyMedium.copy(fontStyle = FontStyle.Italic),
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.65f)
                            )
                        }
                    }
                }

                // Telaffuz Butonu
                IconButton(
                    onClick = { onSpeak(wordResult.madde) },
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f))
                ) {
                    Icon(
                        imageVector = Icons.Default.VolumeUp,
                        contentDescription = "Dinle",
                        tint = MaterialTheme.colorScheme.primary
                    )
                }

                Spacer(modifier = Modifier.width(6.dp))

                // Favori Butonu
                IconButton(
                    onClick = onToggleFavorite,
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(
                            if (isFavorite) Color(0xFFFFF9C4)
                            else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f)
                        )
                ) {
                    Icon(
                        imageVector = if (isFavorite) Icons.Default.Bookmark else Icons.Default.BookmarkBorder,
                        contentDescription = "Favori",
                        tint = if (isFavorite) Color(0xFFFBC02D) else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }

                Spacer(modifier = Modifier.width(6.dp))

                // Paylaş Butonu
                IconButton(
                    onClick = {
                        val shareText = buildShareText(wordResult)
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, shareText)
                        }
                        context.startActivity(Intent.createChooser(intent, "Kâmus ile Paylaş"))
                    },
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f))
                ) {
                    Icon(
                        imageVector = Icons.Default.Share,
                        contentDescription = "Paylaş",
                        tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }
            }

            // Birleşik Sözler (Tıklanabilir Çipler)
            val compoundList = remember(wordResult.birlesikler) {
                if (wordResult.birlesikler.isBlank()) emptyList()
                else wordResult.birlesikler.split(",").map { it.trim() }.filter { it.isNotEmpty() }
            }

            if (compoundList.isNotEmpty()) {
                Spacer(modifier = Modifier.height(14.dp))
                Text(
                    text = "BİRLEŞİK SÖZLER",
                    style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold, letterSpacing = 0.5.sp),
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
                Spacer(modifier = Modifier.height(6.dp))
                FlowRow(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    compoundList.forEach { compound ->
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = MaterialTheme.colorScheme.primary.copy(alpha = 0.08f),
                            modifier = Modifier.clickable { onSelectWord(compound) }
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 9.dp, vertical = 5.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = Icons.Outlined.Search,
                                    contentDescription = null,
                                    modifier = Modifier.size(12.dp),
                                    tint = MaterialTheme.colorScheme.primary
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = compound,
                                    style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Medium),
                                    color = MaterialTheme.colorScheme.primary
                                )
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
            HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.5f))
            Spacer(modifier = Modifier.height(14.dp))

            // Anlamlar Listesi
            wordResult.anlamlarListe.forEachIndexed { index, meaning ->
                MeaningItemView(
                    meaning = meaning,
                    index = index + 1,
                    onSelectWord = onSelectWord
                )
                if (index < wordResult.anlamlarListe.lastIndex) {
                    Spacer(modifier = Modifier.height(14.dp))
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun MeaningItemView(
    meaning: Meaning,
    index: Int,
    onSelectWord: (String) -> Unit
) {
    var isWordExplorerOpen by remember { mutableStateOf(false) }

    val wordsInMeaning = remember(meaning.anlam) {
        meaning.anlam.split("\\s+".toRegex())
            .map { it.trim().trim(',', '.', ';', ':', '!', '?', '"', '“', '”', '(', ')') }
            .filter { it.length >= 2 }
            .distinct()
    }

    Row(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = "$index.",
            style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold),
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.width(26.dp)
        )

        Column(modifier = Modifier.weight(1f)) {
            // Özellik rozetleri (isim, sıfat, mecaz vb.)
            if (!meaning.ozelliklerListe.isNullOrEmpty()) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    modifier = Modifier.padding(bottom = 4.dp)
                ) {
                    meaning.ozelliklerListe.forEach { prop ->
                        Surface(
                            shape = RoundedCornerShape(4.dp),
                            color = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)
                        ) {
                            Text(
                                text = prop.tam_adi.lowercase(),
                                style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Medium),
                                color = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                    }
                }
            }

            // Anlam Metni (Seçilebilir)
            SelectionContainer {
                Text(
                    text = meaning.anlam,
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }

            // Anlamdaki Kelimeleri Ara Butonu ve Çipleri (Kelime Gezgini)
            if (wordsInMeaning.isNotEmpty()) {
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .clickable { isWordExplorerOpen = !isWordExplorerOpen }
                        .padding(vertical = 2.dp)
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Search,
                        contentDescription = null,
                        modifier = Modifier.size(12.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = if (isWordExplorerOpen) "Kelimeleri Gizle" else "Anlamdaki Kelimeleri Ara",
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Medium),
                        color = MaterialTheme.colorScheme.primary
                    )
                }

                AnimatedVisibility(
                    visible = isWordExplorerOpen,
                    enter = fadeIn(),
                    exit = fadeOut()
                ) {
                    FlowRow(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 4.dp),
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        wordsInMeaning.forEach { word ->
                            Surface(
                                shape = RoundedCornerShape(6.dp),
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f),
                                modifier = Modifier.clickable { onSelectWord(word) }
                            ) {
                                Text(
                                    text = word,
                                    style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Medium),
                                    color = MaterialTheme.colorScheme.onSurface,
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                )
                            }
                        }
                    }
                }
            }

            // Örnek Cümleler
            if (!meaning.orneklerListe.isNullOrEmpty()) {
                Spacer(modifier = Modifier.height(4.dp))
                meaning.orneklerListe.forEach { eg ->
                    SelectionContainer {
                        Text(
                            text = "“${eg.ornek}”",
                            style = MaterialTheme.typography.bodyMedium.copy(fontStyle = FontStyle.Italic),
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                            modifier = Modifier.padding(top = 2.dp)
                        )
                    }
                }
            }
        }
    }
}

private fun buildShareText(wordResult: WordResult): String {
    val sb = StringBuilder()
    sb.append(wordResult.madde)
    if (wordResult.lisan.isNotBlank()) {
        sb.append(" (${wordResult.lisan})")
    }
    sb.append("\n")
    wordResult.anlamlarListe.forEachIndexed { i, m ->
        sb.append("\n${i + 1}. ${m.anlam}")
        val firstEx = m.orneklerListe?.firstOrNull()
        if (firstEx != null) {
            sb.append("\n   \"${firstEx.ornek}\"")
        }
    }
    sb.append("\n\n— Kâmus Türkçe Sözlük")
    return sb.toString()
}
