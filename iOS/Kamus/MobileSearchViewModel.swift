import SwiftUI
import UIKit
import Combine

@MainActor
final class MobileSearchViewModel: ObservableObject {
    @Published var selectedTab: MobileTab = .search
    @Published var searchText: String = ""
    @Published var results: [WordResult] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var suggestions: [String] = []
    @Published var recentSearches: [HistoryItem] = []
    @Published var favorites: [HistoryItem] = []
    @Published var todayWord: (word: String, response: SearchResponse)? = nil
    @Published var clipboardWordSuggestion: String? = nil
    @Published var isCurrentWordFavorite: Bool = false
    @Published var selectedResultID: String? = nil {
        // Favori durumu, seçili maddenki kelimeye bakmalı; List selection
        // @Published'i doğrudan yazdığı için iş buradan yürür.
        didSet {
            guard selectedResultID != oldValue else { return }
            Task { await refreshHistoryAndFavorites() }
        }
    }

    var selectedResult: WordResult? {
        guard let selectedResultID else { return nil }
        return results.first { $0.madde_id == selectedResultID }
    }

    func isFavorite(word: String) -> Bool {
        favorites.contains { $0.word == word }
    }

    private var searchTask: Task<Void, Never>?
    private var suggestTask: Task<Void, Never>?
    private let locale = Locale(identifier: "tr_TR")
    private var lastCheckedClipboard: String? = nil

    init() {
        loadInitialData()
    }

    func loadInitialData() {
        Task {
            await refreshHistoryAndFavorites()
            let wotd = await DictionaryStore.shared.wordOfTheDay()
            self.todayWord = wotd
        }
    }

    func refreshHistoryAndFavorites() async {
        let recents = await DictionaryStore.shared.recentSearches(limit: 20)
        let favs = await DictionaryStore.shared.favoriteWords()
        self.recentSearches = recents
        self.favorites = favs
        if let currentWord = selectedResult?.madde ?? results.first?.madde {
            let isFav = await DictionaryStore.shared.isFavorite(word: currentWord)
            self.isCurrentWordFavorite = isFav
        }
    }

    func checkClipboardForWord() {
        guard let pasteString = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !pasteString.isEmpty else {
            clipboardWordSuggestion = nil
            return
        }

        // Kelime çok uzunsa veya birden fazla cümle ise atla
        let tokens = pasteString.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
        guard tokens.count <= 2, pasteString.count <= 35 else {
            clipboardWordSuggestion = nil
            return
        }

        // Daha önce aynı kelime önerilmişse veya şu an aranan kelimeyle aynıysa gösterme
        let cleaned = pasteString.trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.symbols))
        guard !cleaned.isEmpty, cleaned != lastCheckedClipboard, cleaned.lowercased(with: locale) != searchText.lowercased(with: locale) else {
            return
        }

        lastCheckedClipboard = cleaned
        clipboardWordSuggestion = cleaned
    }

    func dismissClipboardSuggestion() {
        clipboardWordSuggestion = nil
    }

    func useClipboardSuggestion() {
        guard let word = clipboardWordSuggestion else { return }
        clipboardWordSuggestion = nil
        search(word: word)
    }

    func updateSuggestions(for text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            return
        }

        suggestTask?.cancel()
        suggestTask = Task {
            try? await Task.sleep(nanoseconds: 120_000_000)
            if Task.isCancelled { return }
            let items = await DictionaryStore.shared.autocomplete(prefix: trimmed, limit: 8)
            if !Task.isCancelled {
                self.suggestions = items
            }
        }
    }

    func search(word: String) {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        searchText = trimmed
        suggestions = []
        isLoading = true
        errorMessage = nil

        searchTask?.cancel()
        searchTask = Task {
            // 1. Önce yerel önbellek / SQLite tohum kontrolü (anında açılış)
            if let cachedData = await DictionaryStore.shared.cachedResponse(for: trimmed) {
                if let decoded = try? JSONDecoder().decode([WordResult].self, from: cachedData), !decoded.isEmpty {
                    self.results = decoded
                    self.selectedResultID = decoded.first?.madde_id
                    self.isLoading = false
                    await DictionaryStore.shared.touch(word: trimmed)
                    await self.refreshHistoryAndFavorites()
                }
            }

            // 2. TDK API üzerinden canlı arama ve güncelleme
            do {
                let response = try await TDKAPIClient.searchWord(trimmed)
                if Task.isCancelled { return }
                self.results = response.results
                self.selectedResultID = response.results.first?.madde_id
                self.isLoading = false

                if response.results.isEmpty {
                    self.errorMessage = "\"\(trimmed)\" kelimesi güncel Türkçe sözlükte bulunamadı."
                } else {
                    await DictionaryStore.shared.save(word: trimmed, responseJSON: response.raw)
                    await self.refreshHistoryAndFavorites()
                }
            } catch {
                if Task.isCancelled { return }
                self.isLoading = false
                // Eğer yerel sonuç varsa hata mesajı gösterme (offline mod)
                if self.results.isEmpty {
                    self.errorMessage = "Arama yapılamadı. Lütfen internet bağlantınızı kontrol edin."
                }
            }
        }
    }

    func clearSearch() {
        searchTask?.cancel()
        searchText = ""
        results = []
        suggestions = []
        selectedResultID = nil
        errorMessage = nil
        isLoading = false
        Task {
            await refreshHistoryAndFavorites()
        }
    }

    func toggleFavorite(word: String) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            let newState = await DictionaryStore.shared.toggleFavorite(word: word)
            self.isCurrentWordFavorite = newState
            await self.refreshHistoryAndFavorites()
        }
    }

    func deleteRecentItem(word: String) {
        Task {
            await DictionaryStore.shared.deleteFromHistory(word: word)
            await self.refreshHistoryAndFavorites()
        }
    }

    func clearAllHistory() {
        Task {
            await DictionaryStore.shared.clearAllHistory()
            self.recentSearches = []
            self.favorites = []
        }
    }
}
