import SwiftUI

struct HomeSearchView: View {
    @EnvironmentObject var searchVM: MobileSearchViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FocusState private var isInputFocused: Bool

    // iPhone Duo'nun iç ekranı (ve iPad) regular genişlik verir; dış ekran compact.
    private var showsDetailPane: Bool { horizontalSizeClass == .regular }

    var body: some View {
        if showsDetailPane {
            NavigationSplitView {
                sidebarColumn
                    .kamusEdgePadding()
                    // Zemin, kenar payasının DIŞINDA boyanmalı; yoksa paya boş kalan
                    // şerit sidebar materyalinin beyazıyla kalıyor.
                    .background(Color(.systemGroupedBackground))
                    .kamusSidebarWidth()
                    .toolbar(.hidden, for: .navigationBar)
            } detail: {
                SearchDetailPane()
            }
            .background(Color(.systemGroupedBackground))
        } else {
            // Compact: arama sonucu aynı kolonda, eskisi gibi inline açılır.
            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {
                        SearchHeader(isInputFocused: $isInputFocused)
                        if searchVM.searchText.isEmpty && searchVM.results.isEmpty {
                            HomeDefaultFeed()
                        } else {
                            SearchStateView()
                            resultCards
                        }
                    }
                    .padding(.vertical, 8)
                }
                .kamusEdgePadding()
                // Diğer sekmelerle aynı grouped zemin; yoksa NavigationStack beyaz kalıyor.
                .background(Color(.systemGroupedBackground))
            }
        }
    }

    private var sidebarColumn: some View {
        VStack(spacing: 0) {
            SearchHeader(isInputFocused: $isInputFocused)
                .padding(.top, 8)
            if searchVM.results.isEmpty {
                defaultFeed
            } else {
                WordResultSelectionList()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var resultCards: some View {
        VStack(spacing: 16) {
            ForEach(searchVM.results, id: \.madde_id) { result in
                WordDetailCardView(
                    wordResult: result,
                    isFavorite: searchVM.isFavorite(word: result.madde),
                    onToggleFavorite: { searchVM.toggleFavorite(word: result.madde) },
                    onSelectWord: { searchVM.search(word: $0) }
                )
            }
        }
    }

    private var defaultFeed: some View {
        VStack(alignment: .leading) {
            SearchStateView()
            HomeDefaultFeed()
                .padding(.top, 8)
        }
    }
}

// MARK: - Arama Alanı (her iki düzen de bunu kullanır)

struct SearchHeader: View {
    @EnvironmentObject var searchVM: MobileSearchViewModel
    var isInputFocused: FocusState<Bool>.Binding
    @ScaledMetric(relativeTo: .largeTitle) private var logoSize = 40

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image("KamusLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: logoSize, height: logoSize)
                    .clipShape(RoundedRectangle(cornerRadius: logoSize * 0.22, style: .continuous))
                    .accessibilityHidden(true)

                Text("Kâmus")
                    .font(.largeTitle.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .accessibilityAddTraits(.isHeader)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let clipWord = searchVM.clipboardWordSuggestion {
                ClipboardBanner(
                    word: clipWord,
                    onSearch: { searchVM.useClipboardSuggestion() },
                    onDismiss: { searchVM.dismissClipboardSuggestion() }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            VStack(spacing: 0) {
                SearchBarField(
                    text: $searchVM.searchText,
                    isFocused: isInputFocused,
                    onCommit: { searchVM.search(word: searchVM.searchText) },
                    onClear: { searchVM.clearSearch() },
                    onChange: { newText in
                        if newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            searchVM.results = []
                            searchVM.suggestions = []
                        } else if searchVM.results.isEmpty {
                            searchVM.updateSuggestions(for: newText)
                        }
                    }
                )

                if !searchVM.suggestions.isEmpty && searchVM.results.isEmpty {
                    SuggestionsDropdown(
                        suggestions: searchVM.suggestions,
                        query: searchVM.searchText,
                        onSelect: { selected in
                            isInputFocused.wrappedValue = false
                            searchVM.search(word: selected)
                        }
                    )
                    .padding(.top, 4)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: searchVM.clipboardWordSuggestion)
    }
}

// MARK: - Yükleniyor / Hata durumu

struct SearchStateView: View {
    @EnvironmentObject var searchVM: MobileSearchViewModel

    var body: some View {
        if searchVM.isLoading {
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Kelime aranıyor...")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
        } else if let errorMsg = searchVM.errorMessage {
            VStack(spacing: 14) {
                Image(systemName: "text.magnifyingglass")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text(errorMsg)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
        }
    }
}

// MARK: - Regular genişlik: seçilebilir sonuç listesi + detay kolonu

struct WordResultSelectionList: View {
    @EnvironmentObject var searchVM: MobileSearchViewModel

    var body: some View {
        List(selection: $searchVM.selectedResultID) {
            ForEach(searchVM.results, id: \.madde_id) { result in
                WordResultRow(
                    wordResult: result,
                    isFavorite: searchVM.isFavorite(word: result.madde)
                )
                .tag(result.madde_id)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
    }
}

struct WordResultRow: View {
    let wordResult: WordResult
    let isFavorite: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(wordResult.madde)
                    .font(.headline)
                    .foregroundColor(.primary)

                if !wordResult.lisan.isEmpty {
                    Text(wordResult.lisan)
                        .font(.caption)
                        .italic()
                        .foregroundColor(.secondary)
                }

                if let meaning = wordResult.anlamlarListe.first {
                    Text(meaning.anlam)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            if isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .accessibilityLabel("Favori")
            }
        }
        .padding(.vertical, 2)
    }
}

struct SearchDetailPane: View {
    var body: some View {
        SelectedWordDetailPane(
            emptyTitle: "Kelime seçin",
            emptyDescription: "Sol taraftan bir sonuç seçtiğinizde madde burada açılır."
        )
    }
}

// MARK: - Components

struct SearchBarField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var onCommit: () -> Void
    var onClear: () -> Void
    var onChange: (String) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Kelime ara...", text: $text)
                .font(.body)
                .focused(isFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .submitLabel(.search)
                .onSubmit(onCommit)
                .onChange(of: text) { val in
                    onChange(val)
                }

            if !text.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

struct SuggestionsDropdown: View {
    let suggestions: [String]
    let query: String
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(suggestions, id: \.self) { item in
                Button(action: { onSelect(item) }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(item)
                            .font(.body)
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "arrow.up.left")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                if item != suggestions.last {
                    Divider()
                        .padding(.leading, 36)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

struct ClipboardBanner: View {
    let word: String
    let onSearch: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard.fill")
                .foregroundColor(.accentColor)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("Panodaki kelimeyi ara:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(word)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            Spacer()

            Button(action: onSearch) {
                Text("Ara")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.secondary)
                    .padding(6)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

struct HomeDefaultFeed: View {
    @EnvironmentObject var searchVM: MobileSearchViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Günün Kelimesi Banner'ı
            if let today = searchVM.todayWord {
                WordOfTheDayBanner(
                    word: today.word,
                    response: today.response,
                    onTap: {
                        // Açık ekranda madde sağ pane'de açılır; sekmeyi bırakmak gerekmez.
                        if horizontalSizeClass == .regular {
                            searchVM.search(word: today.word)
                        } else {
                            searchVM.selectedTab = .wordOfDay
                        }
                    }
                )
            }

            // Son Aramalar (Hızlı Çipler)
            if !searchVM.recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("SON ARAMALAR")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.secondary)
                            .tracking(0.5)

                        Spacer()

                        Button("Tümünü Gör") {
                            searchVM.selectedTab = .history
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(searchVM.recentSearches.prefix(10)) { item in
                                Button(action: {
                                    searchVM.search(word: item.word)
                                }) {
                                    HStack(spacing: 6) {
                                        if item.isFavorite {
                                            Image(systemName: "star.fill")
                                                .font(.caption2)
                                                .foregroundColor(.yellow)
                                        }
                                        Text(item.word)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(20)
                                    .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }
}
