import SwiftUI

struct WordOfTheDayView: View {
    @EnvironmentObject var searchVM: MobileSearchViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var date: Date = Date()
    @State private var todayData: (word: String, response: SearchResponse)? = nil
    @State private var isLoading = false
    @State private var isFavorite = false

    private var result: WordResult? { todayData?.response.results.first }

    // Duo'nun iç ekranı (ve iPad) regular genişlik verir; dış ekran compact.
    private var showsDetailPane: Bool { horizontalSizeClass == .regular }

    var body: some View {
        if showsDetailPane {
            NavigationSplitView {
                identityColumn
                    .kamusSidebarWidth()
                    .navigationTitle("Günün Kelimesi")
            } detail: {
                meaningsColumn
            }
            .background(Color(.systemGroupedBackground))
            .task { loadWord() }
        } else {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        if let result {
                            VStack(spacing: 16) {
                                dateHeader
                                WordDetailCardView(
                                    wordResult: result,
                                    isFavorite: isFavorite,
                                    onToggleFavorite: toggleFavorite,
                                    onSelectWord: openInSearch
                                )
                            }
                        } else {
                            placeholder
                        }
                    }
                    .kamusEdgePadding()
                    .padding(.vertical)
                }
                .navigationTitle("Günün Kelimesi")
                .background(Color(.systemGroupedBackground))
                .task { loadWord() }
            }
        }
    }

    // Sol kolon: kelimenin künyesi. Anlamlar sağ kolonda açılır.
    private var identityColumn: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let result {
                    dateHeader
                    VStack(alignment: .leading, spacing: 12) {
                        WordIdentityView(
                            wordResult: result,
                            isFavorite: isFavorite,
                            onToggleFavorite: toggleFavorite
                        )
                        Text("Anlamları sağ tarafta")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .kamusCard()
                } else {
                    placeholder
                }
            }
            .padding(.vertical)
            .kamusEdgePadding()
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var meaningsColumn: some View {
        Group {
            if let result {
                GeometryReader { proxy in
                    ScrollView {
                        WordMeaningsView(wordResult: result, onSelectWord: openInSearch)
                            .kamusCard()
                            .frame(width: min(proxy.size.width - 32, 700))
                            .frame(width: proxy.size.width)
                            .padding(.vertical, 16)
                    }
                }
                .background(Color(.systemGroupedBackground))
            } else {
                ContentUnavailableView(
                    "Günün kelimesi",
                    systemImage: "sparkles",
                    description: Text("Kelime yüklendiğinde anlamları burada görünür.")
                )
            }
        }
        // Kelime yokken detay kolonu beyaz kalmasın.
        .background(Color(.systemGroupedBackground))
    }

    private var dateHeader: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.accentColor)
            Text(dateFormatted(date))
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    @ViewBuilder private var placeholder: some View {
        if isLoading {
            ProgressView("Günün kelimesi yükleniyor...")
                .padding(.top, 60)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("Günün kelimesi hazırlanıyor...")
                    .foregroundColor(.secondary)
            }
            .padding(.top, 60)
        }
    }

    private func toggleFavorite() {
        guard let result else { return }
        searchVM.toggleFavorite(word: result.madde)
        isFavorite.toggle()
    }

    private func openInSearch(_ word: String) {
        searchVM.selectedTab = .search
        searchVM.search(word: word)
    }

    private func loadWord() {
        isLoading = true
        Task {
            let item = await DictionaryStore.shared.wordOfTheDay(for: date)
            self.todayData = item
            if let word = item?.word {
                self.isFavorite = await DictionaryStore.shared.isFavorite(word: word)
            }
            self.isLoading = false
        }
    }

    private func dateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

struct WordOfTheDayBanner: View {
    let word: String
    let response: SearchResponse
    let onTap: () -> Void

    var body: some View {
        if let first = response.results.first, let meaning = first.anlamlarListe.first {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("GÜNÜN KELİMESİ", systemImage: "sparkles")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.accentColor)
                            .tracking(0.8)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(first.madde)
                            .font(.system(.title2, design: .serif, weight: .bold))
                            .foregroundColor(.primary)

                        if !first.lisan.isEmpty {
                            Text(first.lisan)
                                .font(.caption)
                                .italic()
                                .foregroundColor(.secondary)
                        }
                    }

                    Text(meaning.anlam)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
    }
}
