import SwiftUI

struct HomeSearchView: View {
    @EnvironmentObject var searchVM: MobileSearchViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Pano Öneri Kartı
                    if let clipWord = searchVM.clipboardWordSuggestion {
                        ClipboardBanner(
                            word: clipWord,
                            onSearch: { searchVM.useClipboardSuggestion() },
                            onDismiss: { searchVM.dismissClipboardSuggestion() }
                        )
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Arama Kutusu ve Otomatik Tamamlama
                    VStack(spacing: 0) {
                        SearchBarField(
                            text: $searchVM.searchText,
                            isFocused: $isInputFocused,
                            onCommit: {
                                searchVM.search(word: searchVM.searchText)
                            },
                            onClear: {
                                searchVM.clearSearch()
                            },
                            onChange: { newText in
                                if newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    searchVM.results = []
                                    searchVM.suggestions = []
                                } else if searchVM.results.isEmpty {
                                    searchVM.updateSuggestions(for: newText)
                                }
                            }
                        )
                        .padding(.horizontal)

                        // Canlı Öneriler Listesi
                        if !searchVM.suggestions.isEmpty && searchVM.results.isEmpty {
                            SuggestionsDropdown(
                                suggestions: searchVM.suggestions,
                                query: searchVM.searchText,
                                onSelect: { selected in
                                    isInputFocused = false
                                    searchVM.search(word: selected)
                                }
                            )
                            .padding(.horizontal)
                            .padding(.top, 4)
                        }
                    }

                    // İçerik: Boşken Günün Kelimesi & Son Aramalar | Doluyken Arama Sonuçları
                    if searchVM.searchText.isEmpty && searchVM.results.isEmpty {
                        HomeDefaultFeed()
                            .padding(.horizontal)
                    } else if searchVM.isLoading {
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
                                .font(.system(size: 44))
                                .foregroundColor(.secondary)
                            Text(errorMsg)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else if !searchVM.results.isEmpty {
                        VStack(spacing: 16) {
                            ForEach(searchVM.results, id: \.madde_id) { result in
                                WordDetailCardView(
                                    wordResult: result,
                                    isFavorite: searchVM.isCurrentWordFavorite,
                                    onToggleFavorite: {
                                        searchVM.toggleFavorite(word: result.madde)
                                    },
                                    onSelectWord: { selected in
                                        searchVM.search(word: selected)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Kâmus")
            .background(Color(.systemGroupedBackground))
            .animation(.easeInOut(duration: 0.25), value: searchVM.clipboardWordSuggestion)
        }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Günün Kelimesi Banner'ı
            if let today = searchVM.todayWord {
                WordOfTheDayBanner(
                    word: today.word,
                    response: today.response,
                    onTap: {
                        searchVM.selectedTab = .wordOfDay
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
