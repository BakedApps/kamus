package cloud.bakedapps.kamus.data.api

import cloud.bakedapps.kamus.data.models.Example
import cloud.bakedapps.kamus.data.models.Meaning
import cloud.bakedapps.kamus.data.models.Property
import cloud.bakedapps.kamus.data.models.SearchResponse
import cloud.bakedapps.kamus.data.models.WordResult
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.selects.select
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONArray
import org.json.JSONObject
import java.net.URLEncoder
import java.util.concurrent.TimeUnit

object TdkApiClient {
    private const val BASE_URL = "https://sozluk.gov.tr"

    private val client = OkHttpClient.Builder()
        .connectTimeout(8, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .build()

    private fun buildRequest(word: String): Request {
        val encoded = URLEncoder.encode(word.trim(), "UTF-8")
        val url = "$BASE_URL/gts?ara=$encoded"
        return Request.Builder()
            .url(url)
            .header("User-Agent", "Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36")
            .header("Referer", "https://sozluk.gov.tr/")
            .header("Accept", "application/json")
            .build()
    }

    private suspend fun executeFetch(word: String): SearchResponse = withContext(Dispatchers.IO) {
        val request = buildRequest(word)
        val response = client.newCall(request).execute()
        if (!response.isSuccessful) {
            throw Exception("Sunucu hatası: ${response.code}")
        }
        val bodyString = response.body?.string().orEmpty()
        if (bodyString.isBlank()) {
            throw Exception("Boş sunucu yanıtı")
        }

        val results = parseJson(bodyString)
        SearchResponse(results = results, rawJson = bodyString)
    }

    /**
     * TDK API sorgusu. Ani gecikmelere (tail latency) karşı hedged-request yaklaşımı:
     * 2.5 saniyede yanıt gelmezse ikinci bir eşzamanlı istek başlatılır.
     */
    suspend fun searchWord(word: String): SearchResponse = coroutineScope {
        val trimmed = word.trim()
        if (trimmed.isEmpty()) {
            throw IllegalArgumentException("Arama kelimesi boş olamaz.")
        }

        val attempt1 = async { executeFetch(trimmed) }
        val attempt2 = async {
            delay(2500)
            executeFetch(trimmed)
        }

        try {
            select {
                attempt1.onAwait { res ->
                    attempt2.cancel()
                    res
                }
                attempt2.onAwait { res ->
                    attempt1.cancel()
                    res
                }
            }
        } catch (e: Exception) {
            if (e is CancellationException) throw e
            // Eğer select sırasında hata olursa ilk denemenin sonucunu kontrol et
            try {
                attempt1.await()
            } catch (fallbackError: Exception) {
                try {
                    attempt2.await()
                } catch (_: Exception) {
                    throw fallbackError
                }
            }
        }
    }

    fun parseJson(jsonString: String): List<WordResult> {
        val list = mutableListOf<WordResult>()
        val trimmed = jsonString.trim()

        if (trimmed.startsWith("{")) {
            val obj = JSONObject(trimmed)
            if (obj.has("error")) {
                return emptyList()
            }
        }

        if (!trimmed.startsWith("[")) {
            return emptyList()
        }

        val array = JSONArray(trimmed)
        for (i in 0 until array.length()) {
            val obj = array.optJSONObject(i) ?: continue
            val maddeId = obj.optString("madde_id", "")
            val kelimeNo = obj.optString("kelime_no", "")
            val madde = obj.optString("madde", "")
            val lisan = obj.optString("lisan", "")
            val birlesikler = obj.optString("birlesikler", "")

            val anlamlarList = mutableListOf<Meaning>()
            val anlamlarArray = obj.optJSONArray("anlamlarListe")
            if (anlamlarArray != null) {
                for (j in 0 until anlamlarArray.length()) {
                    val mObj = anlamlarArray.optJSONObject(j) ?: continue
                    val anlamId = mObj.optString("anlam_id", "")
                    val anlam = mObj.optString("anlam", "")
                    val anlamSira = mObj.optString("anlam_sira", "")

                    val props = mutableListOf<Property>()
                    val ozelliklerArray = mObj.optJSONArray("ozelliklerListe")
                    if (ozelliklerArray != null) {
                        for (k in 0 until ozelliklerArray.length()) {
                            val pObj = ozelliklerArray.optJSONObject(k) ?: continue
                            props.add(
                                Property(
                                    ozellik_id = pObj.optString("ozellik_id", ""),
                                    tam_adi = pObj.optString("tam_adi", ""),
                                    kisa_adi = pObj.optString("kisa_adi", "")
                                )
                            )
                        }
                    }

                    val examples = mutableListOf<Example>()
                    val orneklerArray = mObj.optJSONArray("orneklerListe")
                    if (orneklerArray != null) {
                        for (k in 0 until orneklerArray.length()) {
                            val eObj = orneklerArray.optJSONObject(k) ?: continue
                            examples.add(
                                Example(
                                    ornek_id = eObj.optString("ornek_id", ""),
                                    ornek = eObj.optString("ornek", "")
                                )
                            )
                        }
                    }

                    anlamlarList.add(
                        Meaning(
                            anlam_id = anlamId,
                            anlam = anlam,
                            anlam_sira = anlamSira,
                            ozelliklerListe = if (props.isEmpty()) null else props,
                            orneklerListe = if (examples.isEmpty()) null else examples
                        )
                    )
                }
            }

            list.add(
                WordResult(
                    madde_id = maddeId,
                    kelime_no = kelimeNo,
                    madde = madde,
                    lisan = lisan,
                    birlesikler = birlesikler,
                    anlamlarListe = anlamlarList
                )
            )
        }
        return list
    }
}
