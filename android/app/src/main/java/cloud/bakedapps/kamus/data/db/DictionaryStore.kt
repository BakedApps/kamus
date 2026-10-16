package cloud.bakedapps.kamus.data.db

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import cloud.bakedapps.kamus.data.api.TdkApiClient
import cloud.bakedapps.kamus.data.models.HistoryItem
import cloud.bakedapps.kamus.data.models.SearchResponse
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.math.abs

class DictionaryStore private constructor(context: Context) :
    SQLiteOpenHelper(context.applicationContext, DATABASE_NAME, null, DATABASE_VERSION) {

    private val turkishLocale = Locale("tr", "TR")

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE IF NOT EXISTS words (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                word TEXT NOT NULL UNIQUE,
                response_json TEXT NOT NULL,
                first_searched_at REAL NOT NULL,
                last_searched_at REAL NOT NULL,
                search_count INTEGER NOT NULL DEFAULT 1,
                is_favorite INTEGER NOT NULL DEFAULT 0
            );
            """.trimIndent()
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        // Migration logic if schema changes
    }

    private fun canonical(word: String): String {
        return word.trim().lowercase(turkishLocale)
    }

    suspend fun save(word: String, responseJson: String): Unit = withContext(Dispatchers.IO) {
        val cleanWord = canonical(word)
        if (cleanWord.isEmpty() || responseJson.isBlank()) return@withContext

        val now = System.currentTimeMillis() / 1000.0
        val db = writableDatabase
        db.beginTransaction()
        try {
            val sql = """
                INSERT INTO words (word, response_json, first_searched_at, last_searched_at, search_count, is_favorite)
                VALUES (?, ?, ?, ?, 1, 0)
                ON CONFLICT(word) DO UPDATE SET
                    response_json = excluded.response_json,
                    last_searched_at = excluded.last_searched_at,
                    search_count = search_count + 1;
            """.trimIndent()
            db.execSQL(sql, arrayOf(cleanWord, responseJson, now, now))
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    suspend fun cachedResponse(word: String): String? = withContext(Dispatchers.IO) {
        val cleanWord = canonical(word)
        val db = readableDatabase
        db.rawQuery("SELECT response_json FROM words WHERE word = ? LIMIT 1;", arrayOf(cleanWord)).use { cursor ->
            if (cursor.moveToFirst()) {
                cursor.getString(0)
            } else {
                null
            }
        }
    }

    suspend fun touch(word: String): Unit = withContext(Dispatchers.IO) {
        val cleanWord = canonical(word)
        val now = System.currentTimeMillis() / 1000.0
        val db = writableDatabase
        db.execSQL(
            "UPDATE words SET last_searched_at = ?, search_count = search_count + 1 WHERE word = ?;",
            arrayOf(now, cleanWord)
        )
    }

    suspend fun recentSearches(limit: Int = 20): List<HistoryItem> = withContext(Dispatchers.IO) {
        val items = mutableListOf<HistoryItem>()
        val db = readableDatabase
        val sql = """
            SELECT word, last_searched_at, search_count, is_favorite
            FROM words
            WHERE search_count > 0
            ORDER BY last_searched_at DESC
            LIMIT ?;
        """.trimIndent()

        db.rawQuery(sql, arrayOf(limit.toString())).use { cursor ->
            while (cursor.moveToNext()) {
                val w = cursor.getString(0)
                val ts = (cursor.getDouble(1) * 1000).toLong()
                val count = cursor.getInt(2)
                val isFav = cursor.getInt(3) == 1
                items.add(HistoryItem(word = w, lastSearchedAt = ts, searchCount = count, isFavorite = isFav))
            }
        }
        items
    }

    suspend fun favoriteWords(): List<HistoryItem> = withContext(Dispatchers.IO) {
        val items = mutableListOf<HistoryItem>()
        val db = readableDatabase
        val sql = """
            SELECT word, last_searched_at, search_count, is_favorite
            FROM words
            WHERE is_favorite = 1
            ORDER BY last_searched_at DESC;
        """.trimIndent()

        db.rawQuery(sql, null).use { cursor ->
            while (cursor.moveToNext()) {
                val w = cursor.getString(0)
                val ts = (cursor.getDouble(1) * 1000).toLong()
                val count = cursor.getInt(2)
                items.add(HistoryItem(word = w, lastSearchedAt = ts, searchCount = count, isFavorite = true))
            }
        }
        items
    }

    suspend fun isFavorite(word: String): Boolean = withContext(Dispatchers.IO) {
        val cleanWord = canonical(word)
        val db = readableDatabase
        db.rawQuery("SELECT is_favorite FROM words WHERE word = ? LIMIT 1;", arrayOf(cleanWord)).use { cursor ->
            if (cursor.moveToFirst()) {
                cursor.getInt(0) == 1
            } else {
                false
            }
        }
    }

    suspend fun toggleFavorite(word: String): Boolean = withContext(Dispatchers.IO) {
        val cleanWord = canonical(word)
        val db = writableDatabase
        val currentState = isFavorite(cleanWord)
        val newState = if (currentState) 0 else 1
        db.execSQL("UPDATE words SET is_favorite = ? WHERE word = ?;", arrayOf(newState, cleanWord))
        newState == 1
    }

    suspend fun autocomplete(prefix: String, limit: Int = 8): List<String> = withContext(Dispatchers.IO) {
        val cleanPrefix = canonical(prefix)
        if (cleanPrefix.isEmpty()) return@withContext emptyList()

        val list = mutableListOf<String>()
        val db = readableDatabase
        val sql = """
            SELECT word FROM words
            WHERE word LIKE ? || '%'
            ORDER BY search_count DESC, LENGTH(word) ASC, word ASC
            LIMIT ?;
        """.trimIndent()

        db.rawQuery(sql, arrayOf(cleanPrefix, limit.toString())).use { cursor ->
            while (cursor.moveToNext()) {
                list.add(cursor.getString(0))
            }
        }
        list
    }

    suspend fun wordOfTheDay(date: Date = Date()): Pair<String, SearchResponse>? = withContext(Dispatchers.IO) {
        val db = readableDatabase
        var totalWords = 0
        db.rawQuery("SELECT COUNT(*) FROM words;", null).use { cursor ->
            if (cursor.moveToFirst()) {
                totalWords = cursor.getInt(0)
            }
        }

        if (totalWords == 0) return@withContext null

        val cal = Calendar.getInstance()
        cal.time = date
        val dayOfYear = cal.get(Calendar.DAY_OF_YEAR)
        val year = cal.get(Calendar.YEAR)
        val offset = abs((year * 367 + dayOfYear * 13) % totalWords)

        val sql = "SELECT word, response_json FROM words ORDER BY id ASC LIMIT 1 OFFSET ?;"
        db.rawQuery(sql, arrayOf(offset.toString())).use { cursor ->
            if (cursor.moveToFirst()) {
                val word = cursor.getString(0)
                val rawJson = cursor.getString(1)
                val results = TdkApiClient.parseJson(rawJson)
                if (results.isNotEmpty()) {
                    return@withContext Pair(word, SearchResponse(results = results, rawJson = rawJson))
                }
            }
        }
        null
    }

    suspend fun deleteFromHistory(word: String): Unit = withContext(Dispatchers.IO) {
        val cleanWord = canonical(word)
        val db = writableDatabase
        db.delete("words", "word = ?", arrayOf(cleanWord))
    }

    suspend fun clearAllHistory(): Unit = withContext(Dispatchers.IO) {
        val db = writableDatabase
        db.delete("words", null, null)
    }

    companion object {
        private const val DATABASE_NAME = "kamus_dictionary.db"
        private const val DATABASE_VERSION = 1

        @Volatile
        private var instance: DictionaryStore? = null

        fun getInstance(context: Context): DictionaryStore {
            return instance ?: synchronized(this) {
                instance ?: DictionaryStore(context.applicationContext).also { instance = it }
            }
        }
    }
}
