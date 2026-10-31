import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    enum HomeTab: String, CaseIterable {
        case recent = "Son Arananlar"
        case favorites = "Favoriler"
    }

    @Published var searchText = ""
    @Published var results: [WordResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var recentSearches: [HistoryItem] = []
    @Published var favoriteWords: [HistoryItem] = []
    @Published var suggestions: [String] = []
    @Published var isCurrentWordFavorite = false
    @Published var selectedHomeTab: HomeTab = .recent
    
    private let locale = Locale(identifier: "tr_TR")
    private var currentSearchTask: Task<Void, Never>?
    private var currentSuggestTask: Task<Void, Never>?
    
    init() {
        loadRecentSearches()
        loadFavorites()
    }
    
    func loadRecentSearches() {
        Task {
            let items = await DictionaryStore.shared.recentSearches()
            self.recentSearches = items
        }
    }

    func loadFavorites() {
        Task {
            let items = await DictionaryStore.shared.favoriteWords()
            self.favoriteWords = items
        }
    }
    
    func deleteRecentItem(_ word: String) {
        Task {
            await DictionaryStore.shared.deleteFromHistory(word: word)
            self.loadRecentSearches()
            self.loadFavorites()
        }
    }
    
    func clearAllRecent() {
        Task {
            await DictionaryStore.shared.clearAllHistory()
            self.recentSearches = []
            self.favoriteWords = []
        }
    }

    func toggleFavorite(word: String) {
        Task {
            let isFav = await DictionaryStore.shared.toggleFavorite(word: word)
            self.isCurrentWordFavorite = isFav
            self.loadFavorites()
            self.loadRecentSearches()
        }
    }

    func updateSuggestions(for text: String) {
        currentSuggestTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(with: locale)
        guard !trimmed.isEmpty else {
            self.suggestions = []
            return
        }

        currentSuggestTask = Task {
            let matches = await DictionaryStore.shared.autocomplete(prefix: trimmed)
            guard !Task.isCancelled else { return }
            self.suggestions = matches
        }
    }
    
    func clearSearch() {
        currentSearchTask?.cancel()
        currentSearchTask = nil
        currentSuggestTask?.cancel()
        currentSuggestTask = nil
        searchText = ""
        results = []
        suggestions = []
        errorMessage = nil
        isLoading = false
        isCurrentWordFavorite = false
        loadRecentSearches()
        loadFavorites()
    }
    
    func setQueryAndSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        searchText = trimmed.lowercased(with: locale)
        performSearch()
    }
    
    func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            clearSearch()
            return
        }

        let normalized = query.lowercased(with: locale)
        if searchText != normalized {
            searchText = normalized
        }
        
        isLoading = true
        errorMessage = nil
        suggestions = []
        
        currentSearchTask?.cancel()
        currentSearchTask = Task {
            // Kayıtlı kelimeyi anında veritabanından göster (çevrimdışı da çalışır).
            var servedFromCache = false
            if let cached = await DictionaryStore.shared.cachedResponse(for: normalized),
               let decoded = try? JSONDecoder().decode([WordResult].self, from: cached),
               !decoded.isEmpty {
                guard !Task.isCancelled, self.searchText == normalized else { return }
                self.results = decoded
                self.isLoading = false
                servedFromCache = true
                self.isCurrentWordFavorite = await DictionaryStore.shared.isFavorite(word: normalized)
            }

            do {
                let response = try await TDKAPIClient.searchWord(normalized)
                // Bu yanıt gelene kadar yeni bir arama başladıysa sonucu ezme.
                guard !Task.isCancelled, self.searchText == normalized else { return }
                self.results = response.results
                self.isLoading = false
                self.isCurrentWordFavorite = await DictionaryStore.shared.isFavorite(word: normalized)
                if !response.results.isEmpty {
                    await DictionaryStore.shared.save(word: normalized, responseJSON: response.raw)
                    self.loadRecentSearches()
                }
            } catch is CancellationError {
                // Arama iptal edildi (yeni bir arama başladı veya arama temizlendi).
                return
            } catch {
                guard !Task.isCancelled, self.searchText == normalized else { return }
                if (error as? URLError)?.code == .cancelled {
                    return
                }
                if servedFromCache {
                    // Çevrimdışı ama önbellekte var: sonuçlar ekranda kalsın, hata gösterme.
                    await DictionaryStore.shared.touch(word: normalized)
                    self.loadRecentSearches()
                } else {
                    if let urlError = error as? URLError, urlError.code == .timedOut {
                        self.errorMessage = "TDK sunucusu yanıt vermedi (zaman aşımı). Lütfen tekrar deneyin."
                    } else {
                        self.errorMessage = "Hata: \(error.localizedDescription)"
                    }
                    self.isLoading = false
                }
            }
        }
    }
}

struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    @AppStorage("shortcutKeyCode") private var shortcutKeyCode: Int = ShortcutDefaults.keyCodeInt
    @AppStorage("shortcutModifiers") private var shortcutModifiers: Int = ShortcutDefaults.modifiersInt
    @FocusState private var isSearchFocused: Bool
    @State private var isShowingSettings = false
    
    var popover: NSPopover?
    
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(nsImage: NSImage(contentsOf: Bundle.module.url(forResource: "KamusLogo", withExtension: "png")!)!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        .accessibilityHidden(true)

                    TextField("Kelime ara...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .focused($isSearchFocused)
                        .onSubmit {
                            viewModel.performSearch()
                        }
                        .onChange(of: viewModel.searchText) { newValue in
                            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            if trimmed.isEmpty {
                                viewModel.results = []
                                viewModel.errorMessage = nil
                                viewModel.suggestions = []
                                viewModel.loadRecentSearches()
                                viewModel.loadFavorites()
                            } else if viewModel.results.isEmpty {
                                viewModel.updateSuggestions(for: newValue)
                            }
                        }

                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.clearSearch() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(nsColor: .textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
                .padding(.horizontal, 12)
                .padding(.top, 12)
                
                Divider()
                
                resultsView
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                
                Divider()
                
                HStack(spacing: 10) {
                    Text("\(shortcutDisplay) - Aç/Kapat")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: { isShowingSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .help("Ayarlar")

                    Button(action: { popover?.performClose(nil) }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .help("Pencereyi Gizle")

                    Button(action: { NSApp.terminate(nil) }) {
                        Image(systemName: "power")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .help("Kâmus'tan Çık")
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            .frame(width: 400, height: 500)
            .onAppear {
                viewModel.loadRecentSearches()
                viewModel.loadFavorites()
                DispatchQueue.main.async {
                    isSearchFocused = true
                }
            }
            
            if isShowingSettings {
                Color.black
                    .opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isShowingSettings = false
                    }
                
                VStack(spacing: 0) {
                    HStack {
                        Text("Ayarlar")
                            .font(.headline)
                        Spacer()
                        Button(action: { isShowingSettings = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                    }
                    .padding(12)
                    
                    Divider()
                    
                    SettingsView()
                }
                .frame(width: 360)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(nsColor: .windowBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor).opacity(0.8), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.10), radius: 2, x: 0, y: 1)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.easeInOut(duration: 0.16), value: isShowingSettings)
    }

    @ViewBuilder
    private var resultsView: some View {
        if viewModel.isLoading {
            VStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Aranıyor...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(height: 100)
        } else if let error = viewModel.errorMessage {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle")
                    .font(.title2)
                    .foregroundColor(.red)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            .padding()
        } else if !viewModel.results.isEmpty {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.results, id: \.madde_id) { result in
                        WordDetailView(
                            result: result,
                            isFavorite: viewModel.isCurrentWordFavorite,
                            onToggleFavorite: {
                                viewModel.toggleFavorite(word: result.madde)
                            }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        } else if !viewModel.searchText.isEmpty {
            if !viewModel.suggestions.isEmpty {
                suggestionsView
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "book.circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Kelime bulunamadı")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("TDK'de aramak için Enter'a basın")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            homeTabView
        }
    }

    @ViewBuilder
    private var homeTabView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button(action: { viewModel.selectedHomeTab = .recent }) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text("Son Arananlar")
                    }
                    .font(.system(size: 11, weight: viewModel.selectedHomeTab == .recent ? .semibold : .regular))
                    .foregroundColor(viewModel.selectedHomeTab == .recent ? .primary : .secondary)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(viewModel.selectedHomeTab == .recent ? Color.primary.opacity(0.08) : Color.clear)
                    )
                }
                .buttonStyle(.plain)

                Button(action: { viewModel.selectedHomeTab = .favorites }) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(viewModel.selectedHomeTab == .favorites ? .yellow : .secondary)
                        Text("Favoriler (\(viewModel.favoriteWords.count))")
                    }
                    .font(.system(size: 11, weight: viewModel.selectedHomeTab == .favorites ? .semibold : .regular))
                    .foregroundColor(viewModel.selectedHomeTab == .favorites ? .primary : .secondary)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(viewModel.selectedHomeTab == .favorites ? Color.primary.opacity(0.08) : Color.clear)
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                if viewModel.selectedHomeTab == .recent && !viewModel.recentSearches.isEmpty {
                    Button("Tümünü Temizle") {
                        viewModel.clearAllRecent()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)

            if viewModel.selectedHomeTab == .recent {
                if !viewModel.recentSearches.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(viewModel.recentSearches) { item in
                                RecentSearchRow(
                                    item: item,
                                    onSelect: {
                                        viewModel.setQueryAndSearch(item.word)
                                    },
                                    onDelete: {
                                        viewModel.deleteRecentItem(item.word)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                } else {
                    emptyHomePlaceholder(
                        icon: "clock",
                        title: "Henüz arama yapılmadı",
                        subtitle: "Arama kutusuna bir kelime yazıp Enter'a basarak başlayın"
                    )
                }
            } else {
                if !viewModel.favoriteWords.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(viewModel.favoriteWords) { item in
                                RecentSearchRow(
                                    item: item,
                                    onSelect: {
                                        viewModel.setQueryAndSearch(item.word)
                                    },
                                    onDelete: {
                                        viewModel.deleteRecentItem(item.word)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                } else {
                    emptyHomePlaceholder(
                        icon: "star",
                        title: "Favori kelime yok",
                        subtitle: "Kelime kartlarındaki yıldız simgesine tıklayarak favorilerinize ekleyebilirsiniz"
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func emptyHomePlaceholder(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ÖNERİLER (ENTER'A BASARAK ARAYABİLİRSİNİZ)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)
                .padding(.horizontal, 14)
                .padding(.top, 4)

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(viewModel.suggestions, id: \.self) { suggestion in
                        SuggestionRow(word: suggestion, query: viewModel.searchText) {
                            viewModel.setQueryAndSearch(suggestion)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private var shortcutDisplay: String {
        let mods = NSEvent.ModifierFlags(rawValue: UInt(shortcutModifiers))
        var s = ""
        if mods.contains(.control) { s += "⌃" }
        if mods.contains(.option) { s += "⌥" }
        if mods.contains(.shift) { s += "⇧" }
        if mods.contains(.command) { s += "⌘" }
        s += KeyCodeFormatter.displayString(for: UInt16(shortcutKeyCode))
        return s
    }
}

struct WordDetailView: View {
    let result: WordResult
    var isFavorite: Bool = false
    var onToggleFavorite: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Word header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.madde)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if !result.lisan.isEmpty {
                        Text(result.lisan)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if let onToggleFavorite {
                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.system(size: 15))
                            .foregroundColor(isFavorite ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(isFavorite ? "Favorilerden Çıkar" : "Favorilere Ekle")
                }
            }
            
            // Meanings
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(result.anlamlarListe.enumerated()), id: \.offset) { index, anlam in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(anlam.anlam)
                                    .font(.body)
                                    .lineLimit(nil)
                                
                                // Part of speech
                                if let ozellik = anlam.ozelliklerListe?.first {
                                    Text(ozellik.kisa_adi)
                                        .font(.caption2.weight(.medium))
                                        .foregroundColor(.blue)
                                        .padding(.vertical, 2)
                                        .padding(.horizontal, 7)
                                        .background(Capsule().fill(Color.blue.opacity(0.12)))
                                }
                                
                                // Examples
                                if let ornekler = anlam.orneklerListe, !ornekler.isEmpty {
                                    VStack(alignment: .leading, spacing: 3) {
                                        ForEach(ornekler.prefix(2), id: \.ornek_id) { ornek in
                                            HStack(alignment: .top, spacing: 6) {
                                                Text("•")
                                                    .foregroundColor(.secondary)
                                                Text(ornek.ornek)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .italic()
                                            }
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }
                }
            }
            
            // Compound words
            if !result.birlesikler.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Birleşikler")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text(result.birlesikler)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
    }
}

struct RecentSearchRow: View {
    let item: HistoryItem
    let onSelect: () -> Void
    let onDelete: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.isFavorite ? "star.fill" : "clock")
                .font(.system(size: 11))
                .foregroundColor(item.isFavorite ? .yellow : .secondary)

            Text(item.word)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.primary)

            Spacer()

            if item.searchCount > 1 {
                Text("\(item.searchCount)×")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color.primary.opacity(0.08)))
            }

            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(4)
                }
                .buttonStyle(.plain)
                .help("Geçmişten sil")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isHovering ? Color.primary.opacity(0.06) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture {
            onSelect()
        }
    }
}

struct SuggestionRow: View {
    let word: String
    let query: String
    let onSelect: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            highlightedText(word: word, query: query)
                .font(.system(size: 13))

            Spacer()

            Image(systemName: "arrow.up.left")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .opacity(isHovering ? 1 : 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isHovering ? Color.primary.opacity(0.06) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture {
            onSelect()
        }
    }

    private func highlightedText(word: String, query: String) -> Text {
        let lowerWord = word.lowercased()
        let lowerQuery = query.lowercased()
        if lowerWord.hasPrefix(lowerQuery) {
            let matchLength = query.count
            let prefix = String(word.prefix(matchLength))
            let suffix = String(word.dropFirst(matchLength))
            return Text(prefix).bold() + Text(suffix).foregroundColor(.secondary)
        }
        return Text(word)
    }
}

