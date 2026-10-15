import Foundation
import SQLite3

// Swift, SQLITE_TRANSIENT makrosunu import edemez; bind edilen string'in
// kopyalanması için bu sabit zorunlu (yoksa dangling pointer oluşur).
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

struct HistoryItem: Identifiable, Equatable {
    var id: String { word }
    let word: String
    let lastSearchedAt: Date
    let searchCount: Int
    var isFavorite: Bool = false
}

struct DatabaseStats: Equatable {
    let wordCount: Int
    let favoriteCount: Int
    let databaseSizeBytes: Int64
    let databasePath: String
}

/// Aranan her kelimenin ham TDK yanıtını yerel SQLite veritabanında saklar.
/// Tüm metotlar hatasızdır: veritabanı sorunları aramayı asla bozmaz, sadece loglanır.
actor DictionaryStore {
    static let shared = DictionaryStore()

    private var db: OpaquePointer?
    private var dbPath: String?
    private var didAttemptOpen = false
    private let locale = Locale(identifier: "tr_TR")

    /// Başarılı bir aramayı kaydeder; kelime zaten varsa yanıtı günceller ve sayacı artırır.
    func save(word: String, responseJSON: Data) {
        guard openIfNeeded() else { return }
        guard let json = String(data: responseJSON, encoding: .utf8), !json.isEmpty else { return }
        let sql = """
            INSERT INTO words (word, response_json, first_searched_at, last_searched_at, search_count, is_favorite)
            VALUES (?1, ?2, ?3, ?3, 1, 0)
            ON CONFLICT(word) DO UPDATE SET
                response_json    = excluded.response_json,
                last_searched_at = excluded.last_searched_at,
                search_count     = search_count + 1;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logError("save prepare")
            return
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, canonical(word), -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, json, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(stmt, 3, Date().timeIntervalSince1970)
        if sqlite3_step(stmt) != SQLITE_DONE {
            logError("save step")
        }
    }

    /// Kelime için kayıtlı ham JSON yanıtını döndürür; yoksa nil.
    func cachedResponse(for word: String) -> Data? {
        guard openIfNeeded() else { return nil }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT response_json FROM words WHERE word = ?1 LIMIT 1;",
                                 -1, &stmt, nil) == SQLITE_OK else {
            logError("cachedResponse prepare")
            return nil
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, canonical(word), -1, SQLITE_TRANSIENT)
        guard sqlite3_step(stmt) == SQLITE_ROW,
              let cString = sqlite3_column_text(stmt, 0) else { return nil }
        return String(cString: cString).data(using: .utf8)
    }

    /// Çevrimdışıyken önbellekten servis edilen bir arama için sayaç ve zaman damgasını günceller.
    func touch(word: String) {
        guard openIfNeeded() else { return }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, """
            UPDATE words SET last_searched_at = ?1, search_count = search_count + 1 WHERE word = ?2;
            """, -1, &stmt, nil) == SQLITE_OK else {
            logError("touch prepare")
            return
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_double(stmt, 1, Date().timeIntervalSince1970)
        sqlite3_bind_text(stmt, 2, canonical(word), -1, SQLITE_TRANSIENT)
        if sqlite3_step(stmt) != SQLITE_DONE {
            logError("touch step")
        }
    }

    /// Son aranan kelimeleri tarihe göre azalan sırada getirir.
    func recentSearches(limit: Int = 12) -> [HistoryItem] {
        guard openIfNeeded() else { return [] }
        let sql = """
            SELECT word, last_searched_at, search_count, COALESCE(is_favorite, 0)
            FROM words
            WHERE search_count > 0
            ORDER BY last_searched_at DESC
            LIMIT ?1;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logError("recentSearches prepare")
            return []
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(limit))

        var items: [HistoryItem] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let cWord = sqlite3_column_text(stmt, 0) else { continue }
            let word = String(cString: cWord)
            let timestamp = sqlite3_column_double(stmt, 1)
            let count = Int(sqlite3_column_int(stmt, 2))
            let isFav = sqlite3_column_int(stmt, 3) == 1
            items.append(HistoryItem(word: word, lastSearchedAt: Date(timeIntervalSince1970: timestamp), searchCount: count, isFavorite: isFav))
        }
        return items
    }

    /// Veritabanındaki kelimelerden önek (prefix) ile eşleşen önerileri döndürür.
    func autocomplete(prefix: String, limit: Int = 6) -> [String] {
        guard openIfNeeded() else { return [] }
        let canon = canonical(prefix)
        guard !canon.isEmpty else { return [] }
        let sql = """
            SELECT word FROM words
            WHERE word LIKE ?1 || '%'
            ORDER BY search_count DESC, LENGTH(word) ASC, word ASC
            LIMIT ?2;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logError("autocomplete prepare")
            return []
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, canon, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt, 2, Int32(limit))

        var results: [String] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let cWord = sqlite3_column_text(stmt, 0) else { continue }
            results.append(String(cString: cWord))
        }
        return results
    }

    /// Kelimenin favori olup olmadığını sorgular.
    func isFavorite(word: String) -> Bool {
        guard openIfNeeded() else { return false }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT COALESCE(is_favorite, 0) FROM words WHERE word = ?1 LIMIT 1;", -1, &stmt, nil) == SQLITE_OK else {
            return false
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, canonical(word), -1, SQLITE_TRANSIENT)
        if sqlite3_step(stmt) == SQLITE_ROW {
            return sqlite3_column_int(stmt, 0) == 1
        }
        return false
    }

    /// Kelimenin favori durumunu tersine çevirir. Yeni favori durumunu döndürür.
    @discardableResult
    func toggleFavorite(word: String) -> Bool {
        guard openIfNeeded() else { return false }
        let canon = canonical(word)
        let currentlyFav = isFavorite(word: canon)
        let nextVal = currentlyFav ? 0 : 1
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "UPDATE words SET is_favorite = ?1 WHERE word = ?2;", -1, &stmt, nil) == SQLITE_OK else {
            logError("toggleFavorite prepare")
            return false
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(nextVal))
        sqlite3_bind_text(stmt, 2, canon, -1, SQLITE_TRANSIENT)
        if sqlite3_step(stmt) == SQLITE_DONE {
            return nextVal == 1
        }
        return false
    }

    /// Tüm favori kelimeleri getirir.
    func favoriteWords() -> [HistoryItem] {
        guard openIfNeeded() else { return [] }
        let sql = """
            SELECT word, last_searched_at, search_count, is_favorite
            FROM words
            WHERE is_favorite = 1
            ORDER BY last_searched_at DESC;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logError("favoriteWords prepare")
            return []
        }
        defer { sqlite3_finalize(stmt) }
        var items: [HistoryItem] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let cWord = sqlite3_column_text(stmt, 0) else { continue }
            let word = String(cString: cWord)
            let timestamp = sqlite3_column_double(stmt, 1)
            let count = Int(sqlite3_column_int(stmt, 2))
            items.append(HistoryItem(word: word, lastSearchedAt: Date(timeIntervalSince1970: timestamp), searchCount: count, isFavorite: true))
        }
        return items
    }

    /// Veritabanı istatistiklerini hesaplar.
    func databaseStats() -> DatabaseStats {
        guard openIfNeeded() else {
            return DatabaseStats(wordCount: 0, favoriteCount: 0, databaseSizeBytes: 0, databasePath: "")
        }
        var wordCount = 0
        var favCount = 0
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, "SELECT COUNT(*), COALESCE(SUM(is_favorite), 0) FROM words;", -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                wordCount = Int(sqlite3_column_int(stmt, 0))
                favCount = Int(sqlite3_column_int(stmt, 1))
            }
        }
        sqlite3_finalize(stmt)

        var size: Int64 = 0
        let currentPath = dbPath ?? ""
        if !currentPath.isEmpty {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: currentPath) {
                size = attrs[.size] as? Int64 ?? 0
            }
        }
        return DatabaseStats(wordCount: wordCount, favoriteCount: favCount, databaseSizeBytes: size, databasePath: currentPath)
    }

    /// Tüm kelimeleri ve anlamlarını JSON formatında dışa aktarmak için hazırlar.
    func exportAllWordsJSON() -> Data? {
        guard openIfNeeded() else { return nil }
        let sql = "SELECT word, response_json, first_searched_at, last_searched_at, search_count, COALESCE(is_favorite, 0) FROM words ORDER BY word ASC;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }

        var list: [[String: Any]] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let cWord = sqlite3_column_text(stmt, 0),
                  let cJSON = sqlite3_column_text(stmt, 1) else { continue }
            let word = String(cString: cWord)
            let jsonString = String(cString: cJSON)
            let firstSearched = sqlite3_column_double(stmt, 2)
            let lastSearched = sqlite3_column_double(stmt, 3)
            let count = Int(sqlite3_column_int(stmt, 4))
            let isFav = sqlite3_column_int(stmt, 5) == 1

            var itemDict: [String: Any] = [
                "word": word,
                "first_searched_at": firstSearched,
                "last_searched_at": lastSearched,
                "search_count": count,
                "is_favorite": isFav
            ]

            if let data = jsonString.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: data) {
                itemDict["definition"] = parsed
            }
            list.append(itemDict)
        }
        return try? JSONSerialization.data(withJSONObject: list, options: [.prettyPrinted, .sortedKeys])
    }

    /// Tek bir kelimeyi geçmişten/veritabanından siler.
    func deleteFromHistory(word: String) {
        guard openIfNeeded() else { return }
        let sql = "DELETE FROM words WHERE word = ?1;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logError("deleteFromHistory prepare")
            return
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, canonical(word), -1, SQLITE_TRANSIENT)
        if sqlite3_step(stmt) != SQLITE_DONE {
            logError("deleteFromHistory step")
        }
    }

    /// Tüm arama geçmişini temizler.
    func clearAllHistory() {
        guard openIfNeeded() else { return }
        exec("DELETE FROM words;")
    }

    /// Belirli bir tarih için (varsayılan: bugün) deterministik Günün Kelimesi kaydını döndürür.
    func wordOfTheDay(for date: Date = Date()) -> (word: String, response: SearchResponse)? {
        guard openIfNeeded() else { return nil }

        var countStmt: OpaquePointer?
        var totalWords = 0
        if sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM words;", -1, &countStmt, nil) == SQLITE_OK {
            if sqlite3_step(countStmt) == SQLITE_ROW {
                totalWords = Int(sqlite3_column_int(countStmt, 0))
            }
        }
        sqlite3_finalize(countStmt)

        guard totalWords > 0 else { return nil }

        let cal = Calendar.current
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = cal.component(.year, from: date)
        let offset = abs((year * 367 + dayOfYear * 13) % totalWords)

        var stmt: OpaquePointer?
        let sql = "SELECT word, response_json FROM words ORDER BY id ASC LIMIT 1 OFFSET ?1;"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(offset))

        guard sqlite3_step(stmt) == SQLITE_ROW,
              let cWord = sqlite3_column_text(stmt, 0),
              let cJSON = sqlite3_column_text(stmt, 1) else { return nil }

        let word = String(cString: cWord)
        let jsonData = String(cString: cJSON).data(using: .utf8) ?? Data()
        if let results = try? JSONDecoder().decode([WordResult].self, from: jsonData), !results.isEmpty {
            return (word, SearchResponse(results: results, raw: jsonData))
        }
        return nil
    }

    // MARK: - Private

    private func canonical(_ word: String) -> String {
        word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(with: locale)
    }

    /// Uygulama "TDKDictionary" adıyla dağıtıldığı dönemde biriken sözlük veritabanını
    /// yeni klasöre taşır. Yeni klasör zaten varsa dokunulmaz — üzerine yazmak
    /// kullanıcının biriktirdiği kelimeleri silerdi.
    private func migrateLegacyDirectory(from legacy: URL, to destination: URL) {
        let fm = FileManager.default
        guard fm.fileExists(atPath: legacy.path), !fm.fileExists(atPath: destination.path) else { return }
        do {
            try fm.moveItem(at: legacy, to: destination)
            NSLog("DictionaryStore: eski sözlük veritabanı \(destination.path) konumuna taşındı")
        } catch {
            // Taşıma başarısızsa yeni boş veritabanıyla devam edilir; arama bozulmaz.
            NSLog("DictionaryStore: eski veritabanı taşınamadı: \(error)")
        }
    }

    private func databaseDirectory() -> URL {
        #if os(iOS)
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.cloud.bakedapps.kamus") {
            let dir = groupURL.appendingPathComponent("Kamus", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir
        }
        #endif
        if let support = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            let dir = support.appendingPathComponent("Kamus", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir
        }
        let fallback = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Kamus", isDirectory: true)
        try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
        return fallback
    }

    private func openIfNeeded() -> Bool {
        if db != nil { return true }
        if didAttemptOpen { return false }
        didAttemptOpen = true

        let dir = databaseDirectory()
        if let support = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            migrateLegacyDirectory(from: support.appendingPathComponent("TDKDictionary", isDirectory: true), to: dir)
        }
        let path = dir.appendingPathComponent("dictionary.sqlite").path

        var handle: OpaquePointer?
        guard sqlite3_open_v2(path, &handle,
                              SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK,
              let handle = handle else {
            if let handle = handle { sqlite3_close(handle) }
            NSLog("DictionaryStore: veritabanı açılamadı: \(path)")
            return false
        }
        db = handle
        dbPath = path
        exec("PRAGMA journal_mode=WAL;")
        exec("PRAGMA busy_timeout=2000;")
        exec("PRAGMA synchronous=NORMAL;")
        // COLLATE NOCASE bilerek kullanılmıyor: SQLite yalnızca ASCII katlar ve I→i yapar,
        // Türkçe I→ı kuralını bozar. Kanonikleştirme tr_TR lowercase ile kod tarafında yapılır.
        exec("""
            CREATE TABLE IF NOT EXISTS words (
                id                INTEGER PRIMARY KEY AUTOINCREMENT,
                word              TEXT NOT NULL UNIQUE,
                response_json     TEXT NOT NULL,
                first_searched_at REAL NOT NULL,
                last_searched_at  REAL NOT NULL,
                search_count      INTEGER NOT NULL DEFAULT 1,
                is_favorite       INTEGER NOT NULL DEFAULT 0
            );
            """)
        ensureFavoriteColumn()
        seedIfNeeded()
        return true
    }

    private func ensureFavoriteColumn() {
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, "SELECT is_favorite FROM words LIMIT 1;", -1, &stmt, nil) != SQLITE_OK {
            exec("ALTER TABLE words ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0;")
        }
        sqlite3_finalize(stmt)
    }

    /// Eğer veritabanında tohum kelimeler yoksa, paket içindeki seeds.sqlite dosyasından
    /// 99.000+ TDK kelimesini yerel veritabanına aktarır. Kullanıcının mevcut arama geçmişine dokunmaz.
    private func seedIfNeeded() {
        var countStmt: OpaquePointer?
        var existingCount = 0
        if sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM words;", -1, &countStmt, nil) == SQLITE_OK {
            if sqlite3_step(countStmt) == SQLITE_ROW {
                existingCount = Int(sqlite3_column_int(countStmt, 0))
            }
        }
        sqlite3_finalize(countStmt)

        guard existingCount < 1000 else { return }

        var seedPath: String?
        if let bundleURL = Bundle.main.url(forResource: "seeds", withExtension: "sqlite"),
           FileManager.default.fileExists(atPath: bundleURL.path) {
            seedPath = bundleURL.path
        } else {
            // Geliştirme veya terminal ortamı fallback'i
            let devSeed = URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Resources/seeds.sqlite").path
            if FileManager.default.fileExists(atPath: devSeed) {
                seedPath = devSeed
            }
        }

        guard let path = seedPath else { return }

        NSLog("DictionaryStore: Çevrimdışı sözlük tohumu yükleniyor: \(path)")
        let escaped = path.replacingOccurrences(of: "'", with: "''")
        exec("ATTACH DATABASE '\(escaped)' AS seed_db;")
        exec("BEGIN TRANSACTION;")
        exec("""
            INSERT OR IGNORE INTO words (word, response_json, first_searched_at, last_searched_at, search_count, is_favorite)
            SELECT word, response_json, first_searched_at, last_searched_at, 0, 0
            FROM seed_db.words;
            """)
        exec("COMMIT;")
        exec("DETACH DATABASE seed_db;")
        NSLog("DictionaryStore: Çevrimdışı sözlük tohumu başarıyla yüklendi.")
    }

    private func exec(_ sql: String) {
        var err: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &err) != SQLITE_OK {
            if let err = err {
                NSLog("DictionaryStore: \(String(cString: err))")
                sqlite3_free(err)
            }
        }
    }

    private func logError(_ context: String) {
        let message = db.map { String(cString: sqlite3_errmsg($0)) } ?? "db yok"
        NSLog("DictionaryStore \(context): \(message)")
    }
}
