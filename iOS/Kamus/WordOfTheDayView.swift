import SwiftUI

struct WordOfTheDayView: View {
    @EnvironmentObject var searchVM: MobileSearchViewModel
    @State private var date: Date = Date()
    @State private var todayData: (word: String, response: SearchResponse)? = nil
    @State private var isLoading = false
    @State private var isFavorite = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let today = todayData, let result = today.response.results.first {
                        VStack(spacing: 16) {
                            // Date header
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.accentColor)
                                Text(dateFormatted(date))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 4)

                            WordDetailCardView(
                                wordResult: result,
                                isFavorite: isFavorite,
                                onToggleFavorite: {
                                    searchVM.toggleFavorite(word: result.madde)
                                    isFavorite.toggle()
                                }
                            )
                        }
                        .padding(.horizontal)
                    } else if isLoading {
                        ProgressView("Günün kelimesi yükleniyor...")
                            .padding(.top, 60)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("Günün kelimesi hazırlanıyor...")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 60)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Günün Kelimesi")
            .background(Color(.systemGroupedBackground))
            .task {
                loadWord()
            }
        }
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
