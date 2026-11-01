import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var searchVM: MobileSearchViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var filterText = ""
    @State private var selectedWord: String?

    // Duo'nun iç ekranı (ve iPad) regular genişlik verir; dış ekran compact.
    private var showsDetailPane: Bool { horizontalSizeClass == .regular }

    var filteredFavorites: [HistoryItem] {
        if filterText.isEmpty {
            return searchVM.favorites
        }
        return searchVM.favorites.filter {
            $0.word.localizedCaseInsensitiveContains(filterText)
        }
    }

    var body: some View {
        if showsDetailPane {
            NavigationSplitView {
                Group {
                    if filteredFavorites.isEmpty {
                        EmptyStateView(
                            icon: "star",
                            title: "Henüz favori kelimeniz yok",
                            message: "Arama yaptığınız kelimeleri yıldızlayarak buraya ekleyebilirsiniz."
                        )
                    } else {
                        selectionList
                    }
                }
                .navigationTitle("Favoriler")
                .kamusSidebarWidth()
                .background(Color(.systemGroupedBackground))
            } detail: {
                SelectedWordDetailPane(
                    emptyTitle: "Favori seçin",
                    emptyDescription: "Soldaki listeden bir kelime seçtiğinizde anlamı burada açılır."
                )
            }
            .searchable(text: $filterText, placement: .sidebar, prompt: "Favorilerde ara...")
            .background(Color(.systemGroupedBackground))
            .task { await searchVM.refreshHistoryAndFavorites() }
        } else {
            NavigationStack {
                Group {
                    if searchVM.favorites.isEmpty {
                        EmptyStateView(
                            icon: "star",
                            title: "Henüz favori kelimeniz yok",
                            message: "Arama yaptığınız kelimeleri yıldızlayarak buraya ekleyebilirsiniz."
                        )
                    } else {
                        compactList
                    }
                }
                .navigationTitle("Favoriler")
                .background(Color(.systemGroupedBackground))
                .searchable(text: $filterText, prompt: "Favorilerde ara...")
                .task { await searchVM.refreshHistoryAndFavorites() }
            }
        }
    }

    private var selectionList: some View {
        List(selection: $selectedWord) {
            ForEach(filteredFavorites) { item in
                WordHistoryRow(item: item)
                    .tag(item.word)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            searchVM.toggleFavorite(word: item.word)
                        } label: {
                            Label("Kaldır", systemImage: "star.slash")
                        }
                    }
            }
        }
        .listStyle(.sidebar)
        // Sidebar materyali beyaza çalıyor; kolona verilen grouped zemin görünsün.
        .scrollContentBackground(.hidden)
        .onChange(of: selectedWord) { word in
            if let word { searchVM.search(word: word) }
        }
    }

    private var compactList: some View {
        List {
            ForEach(filteredFavorites) { item in
                Button(action: {
                    searchVM.selectedTab = .search
                    searchVM.search(word: item.word)
                }) {
                    WordHistoryRow(item: item)
                        .padding(.vertical, 4)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        searchVM.toggleFavorite(word: item.word)
                    } label: {
                        Label("Kaldır", systemImage: "star.slash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct HistoryView: View {
    @EnvironmentObject var searchVM: MobileSearchViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showClearAlert = false
    @State private var selectedWord: String?

    private var showsDetailPane: Bool { horizontalSizeClass == .regular }

    var body: some View {
        if showsDetailPane {
            NavigationSplitView {
                Group {
                    if searchVM.recentSearches.isEmpty {
                        EmptyStateView(
                            icon: "clock.arrow.circlepath",
                            title: "Arama geçmişiniz boş",
                            message: "Aradığınız kelimeler yerel olarak cihazınıza kaydedilir."
                        )
                    } else {
                        selectionList
                    }
                }
                .navigationTitle("Geçmiş")
                .kamusSidebarWidth()
                .background(Color(.systemGroupedBackground))
            } detail: {
                SelectedWordDetailPane(
                    emptyTitle: "Geçmişten seçin",
                    emptyDescription: "Soldaki listeden bir kelime seçtiğinizde anlamı burada açılır."
                )
            }
            .toolbar { clearToolbarItem }
            .background(Color(.systemGroupedBackground))
            .task { await searchVM.refreshHistoryAndFavorites() }
        } else {
            NavigationStack {
                Group {
                    if searchVM.recentSearches.isEmpty {
                        EmptyStateView(
                            icon: "clock.arrow.circlepath",
                            title: "Arama geçmişiniz boş",
                            message: "Aradığınız kelimeler yerel olarak cihazınıza kaydedilir."
                        )
                    } else {
                        compactList
                    }
                }
                .navigationTitle("Geçmiş")
                .toolbar { clearToolbarItem }
                .background(Color(.systemGroupedBackground))
                .task { await searchVM.refreshHistoryAndFavorites() }
            }
        }
    }

    // Ayrı ToolbarItem: başlıklı/özel görünümlü öğeler Duo'nun dikey barında görünmez.
    @ToolbarContentBuilder private var clearToolbarItem: some ToolbarContent {
        if !searchVM.recentSearches.isEmpty {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showClearAlert = true }) {
                    Label("Temizle", systemImage: "trash")
                }
                .foregroundColor(.red)
            }
        }
    }

    private var selectionList: some View {
        List(selection: $selectedWord) {
            ForEach(searchVM.recentSearches) { item in
                WordHistoryRow(item: item)
                    .tag(item.word)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            searchVM.deleteRecentItem(word: item.word)
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.sidebar)
        // Sidebar materyali beyaza çalıyor; kolona verilen grouped zemin görünsün.
        .scrollContentBackground(.hidden)
        .onChange(of: selectedWord) { word in
            if let word { searchVM.search(word: word) }
        }
    }

    private var compactList: some View {
        List {
            ForEach(searchVM.recentSearches) { item in
                Button(action: {
                    searchVM.selectedTab = .search
                    searchVM.search(word: item.word)
                }) {
                    WordHistoryRow(item: item)
                        .padding(.vertical, 4)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        searchVM.deleteRecentItem(word: item.word)
                    } label: {
                        Label("Sil", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Liste satırı (favori ve geçmiş ortak)
struct WordHistoryRow: View {
    let item: HistoryItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.word)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 8)

            if item.isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .accessibilityLabel("Favori")
            }
        }
    }

    private var subtitle: String {
        if item.isFavorite {
            return "\(item.searchCount) kez arandı"
        }
        return HistoryDateText.string(for: item.lastSearchedAt)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.secondary.opacity(0.6))
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

enum HistoryDateText {
    static func string(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
