import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var searchVM: MobileSearchViewModel
    @State private var filterText = ""
    @State private var selectedWord: WordResult? = nil

    var filteredFavorites: [HistoryItem] {
        if filterText.isEmpty {
            return searchVM.favorites
        }
        return searchVM.favorites.filter {
            $0.word.localizedCaseInsensitiveContains(filterText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if searchVM.favorites.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("Henüz favori kelimeniz yok")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Arama yaptığınız kelimeleri yıldızlayarak buraya ekleyebilirsiniz.")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredFavorites) { item in
                            Button(action: {
                                searchVM.selectedTab = .search
                                searchVM.search(word: item.word)
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.word)
                                            .font(.headline)
                                            .foregroundColor(.primary)

                                        Text("\(item.searchCount) kez arandı")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
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
                    .searchable(text: $filterText, prompt: "Favorilerde ara...")
                }
            }
            .navigationTitle("Favoriler")
            .background(Color(.systemGroupedBackground))
            .task {
                await searchVM.refreshHistoryAndFavorites()
            }
        }
    }
}

struct HistoryView: View {
    @EnvironmentObject var searchVM: MobileSearchViewModel
    @State private var showClearAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if searchVM.recentSearches.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("Arama geçmişiniz boş")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Aradığınız kelimeler yerel olarak cihazınıza kaydedilir.")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(searchVM.recentSearches) { item in
                            Button(action: {
                                searchVM.selectedTab = .search
                                searchVM.search(word: item.word)
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.word)
                                            .font(.headline)
                                            .foregroundColor(.primary)

                                        Text(relativeTimeString(item.lastSearchedAt))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if item.isFavorite {
                                        Image(systemName: "star.fill")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
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
            .navigationTitle("Geçmiş")
            .toolbar {
                if !searchVM.recentSearches.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Temizle") {
                            showClearAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .alert("Arama Geçmişi", isPresented: $showClearAlert) {
                Button("Tümünü Temizle", role: .destructive) {
                    searchVM.clearAllHistory()
                }
                Button("Vazgeç", role: .cancel) {}
            } message: {
                Text("Tüm arama geçmişiniz silinecektir. Bu işlem geri alınamaz.")
            }
            .background(Color(.systemGroupedBackground))
            .task {
                await searchVM.refreshHistoryAndFavorites()
            }
        }
    }

    private func relativeTimeString(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
