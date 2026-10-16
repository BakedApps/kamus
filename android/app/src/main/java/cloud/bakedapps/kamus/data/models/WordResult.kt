package cloud.bakedapps.kamus.data.models

data class WordResult(
    val madde_id: String = "",
    val kelime_no: String = "",
    val madde: String = "",
    val lisan: String = "",
    val birlesikler: String = "",
    val anlamlarListe: List<Meaning> = emptyList()
)

data class Meaning(
    val anlam_id: String = "",
    val anlam: String = "",
    val anlam_sira: String = "",
    val ozelliklerListe: List<Property>? = null,
    val orneklerListe: List<Example>? = null
)

data class Property(
    val ozellik_id: String = "",
    val tam_adi: String = "",
    val kisa_adi: String = ""
)

data class Example(
    val ornek_id: String = "",
    val ornek: String = ""
)

data class SearchResponse(
    val results: List<WordResult>,
    val rawJson: String
)

data class HistoryItem(
    val word: String,
    val lastSearchedAt: Long,
    val searchCount: Int,
    val isFavorite: Boolean = false
)
