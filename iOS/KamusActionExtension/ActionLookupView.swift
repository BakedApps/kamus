import SwiftUI

struct ActionLookupView: View {
    let initialWord: String
    let onClose: () -> Void
    let onOpenInApp: (String) -> Void

    @State private var wordText: String = ""
    @State private var results: [WordResult] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isFavorite: Bool = false
    @StateObject private var speaker = TurkishSpeechSpeaker.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("\"\(wordText)\" aranıyor...")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 14) {
                        Image(systemName: "text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let firstResult = results.first {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Word Header
                            HStack(alignment: .center, spacing: 10) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(firstResult.madde)
                                        .font(.system(.title2, design: .serif, weight: .bold))

                                    if !firstResult.lisan.isEmpty {
                                        Text(firstResult.lisan)
                                            .font(.footnote)
                                            .italic()
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                // Dinle
                                Button(action: {
                                    speaker.speak(firstResult.madde)
                                }) {
                                    Image(systemName: speaker.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                                        .font(.headline)
                                        .foregroundColor(.accentColor)
                                        .padding(8)
                                        .background(Color.accentColor.opacity(0.12))
                                        .clipShape(Circle())
                                }

                                // Favori
                                Button(action: toggleFavorite) {
                                    Image(systemName: isFavorite ? "star.fill" : "star")
                                        .font(.headline)
                                        .foregroundColor(isFavorite ? .yellow : .secondary)
                                        .padding(8)
                                        .background((isFavorite ? Color.yellow : Color.secondary).opacity(0.12))
                                        .clipShape(Circle())
                                }
                            }

                            if !firstResult.birlesikler.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("BİRLEŞİK SÖZLER")
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(.secondary)
                                    Text(firstResult.birlesikler)
                                        .font(.footnote)
                                        .foregroundColor(.primary.opacity(0.85))
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                            }

                            Divider()

                            // Anlamlar
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(firstResult.anlamlarListe.indices, id: \.self) { idx in
                                    let m = firstResult.anlamlarListe[idx]
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("\(idx + 1).")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.accentColor)
                                            .frame(width: 20, alignment: .leading)

                                        VStack(alignment: .leading, spacing: 4) {
                                            if let props = m.ozelliklerListe, !props.isEmpty {
                                                HStack(spacing: 4) {
                                                    ForEach(props, id: \.ozellik_id) { prop in
                                                        Text(prop.tam_adi.lowercased())
                                                            .font(.caption2.weight(.medium))
                                                            .foregroundColor(.accentColor)
                                                            .padding(.horizontal, 5)
                                                            .padding(.vertical, 1)
                                                            .background(Color.accentColor.opacity(0.1))
                                                            .cornerRadius(3)
                                                    }
                                                }
                                            }

                                            Text(m.anlam)
                                                .font(.body)

                                            if let examples = m.orneklerListe, let eg = examples.first {
                                                Text("“\(eg.ornek)”")
                                                    .font(.callout)
                                                    .italic()
                                                    .foregroundColor(.secondary)
                                                    .padding(.top, 1)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Aranacak bir kelime seçilmedi.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Kâmus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !wordText.isEmpty {
                        Button("Uygulamada Aç") {
                            onOpenInApp(wordText)
                        }
                        .font(.footnote)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Bitti") {
                        onClose()
                    }
                    .font(.headline)
                }
            }
            .task {
                wordText = initialWord
                if !initialWord.isEmpty {
                    search(word: initialWord)
                }
            }
        }
    }

    private func search(word: String) {
        isLoading = true
        errorMessage = nil

        Task {
            // Önce yerel önbellek
            if let cached = await DictionaryStore.shared.cachedResponse(for: word) {
                if let decoded = try? JSONDecoder().decode([WordResult].self, from: cached), !decoded.isEmpty {
                    self.results = decoded
                    self.isLoading = false
                    self.isFavorite = await DictionaryStore.shared.isFavorite(word: word)
                }
            }

            // Canlı TDK
            do {
                let response = try await TDKAPIClient.searchWord(word)
                self.results = response.results
                self.isLoading = false
                if response.results.isEmpty {
                    self.errorMessage = "\"\(word)\" sözlükte bulunamadı."
                } else {
                    await DictionaryStore.shared.save(word: word, responseJSON: response.raw)
                    self.isFavorite = await DictionaryStore.shared.isFavorite(word: word)
                }
            } catch {
                self.isLoading = false
                if self.results.isEmpty {
                    self.errorMessage = "Arama yapılamadı veya çevrimdışısınız."
                }
            }
        }
    }

    private func toggleFavorite() {
        guard let first = results.first else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            let state = await DictionaryStore.shared.toggleFavorite(word: first.madde)
            self.isFavorite = state
        }
    }
}
