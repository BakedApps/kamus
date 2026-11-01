import SwiftUI

// MARK: - Flow Layout for Wrapping Tags
struct ActionFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
        return CGSize(width: width, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
    }
}

// MARK: - Action Lookup View
struct ActionLookupView: View {
    let initialWord: String
    let onClose: () -> Void
    let onOpenInApp: (String) -> Void

    @State private var wordText: String = ""
    @State private var results: [WordResult] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isFavorite: Bool = false
    @State private var wordHistory: [String] = []
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
                            .font(.largeTitle)
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
                                        .textSelection(.enabled)

                                    if !firstResult.lisan.isEmpty {
                                        Text(firstResult.lisan)
                                            .font(.footnote)
                                            .italic()
                                            .foregroundColor(.secondary)
                                            .textSelection(.enabled)
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

                            // Birleşik Kelimeler (İnteraktif Çipler)
                            if !compoundWords(firstResult.birlesikler).isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("BİRLEŞİK SÖZLER")
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(.secondary)

                                    ActionFlowLayout(spacing: 6) {
                                        ForEach(compoundWords(firstResult.birlesikler), id: \.self) { compound in
                                            Button(action: {
                                                searchNewWord(compound)
                                            }) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "magnifyingglass")
                                                        .font(.caption2)
                                                    Text(compound)
                                                        .font(.caption.weight(.medium))
                                                }
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.accentColor.opacity(0.08))
                                                .foregroundColor(.accentColor)
                                                .cornerRadius(6)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                            }

                            Divider()

                            // Anlamlar
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(firstResult.anlamlarListe.indices, id: \.self) { idx in
                                    let m = firstResult.anlamlarListe[idx]
                                    ActionMeaningRow(
                                        meaning: m,
                                        index: idx + 1,
                                        onSelectWord: { word in
                                            searchNewWord(word)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(16)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark.circle")
                            .font(.largeTitle)
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
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image("KamusLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                            .accessibilityHidden(true)
                        Text("Kâmus")
                            .font(.headline)
                    }
                    .accessibilityElement(children: .combine)
                }
                // Her kontrol ayrı ToolbarItem: HStack'le birleştirilen özel
                // görünümler iPhone Duo'da dikey bara taşınmıyor.
                if !wordHistory.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: goBack) {
                            Label("Geri", systemImage: "chevron.left")
                        }
                    }
                }

                if !wordText.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { onOpenInApp(wordText) }) {
                            Label("Uygulamada Aç", systemImage: "arrow.up.forward.app")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onClose) {
                        Label("Bitti", systemImage: "checkmark")
                    }
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

    private func compoundWords(_ raw: String) -> [String] {
        return raw.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func searchNewWord(_ word: String) {
        if !wordText.isEmpty {
            wordHistory.append(wordText)
        }
        wordText = word
        search(word: word)
    }

    private func goBack() {
        guard let prev = wordHistory.popLast() else { return }
        wordText = prev
        search(word: prev)
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

// MARK: - Action Meaning Row with Word Explorer
struct ActionMeaningRow: View {
    let meaning: Meaning
    let index: Int
    let onSelectWord: (String) -> Void

    @State private var isWordExplorerOpen = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(index).")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.accentColor)
                .frame(minWidth: 20, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                if let props = meaning.ozelliklerListe, !props.isEmpty {
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

                Text(meaning.anlam)
                    .font(.body)
                    .textSelection(.enabled)

                // Kelime Keşfet Çipleri
                if !meaningWords.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isWordExplorerOpen.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isWordExplorerOpen ? "chevron.up.circle.fill" : "text.magnifyingglass")
                                .font(.caption2)
                            Text(isWordExplorerOpen ? "Kelimeleri Gizle" : "Anlamdaki Kelimeleri Ara")
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundColor(.accentColor)
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)

                    if isWordExplorerOpen {
                        ActionFlowLayout(spacing: 6) {
                            ForEach(meaningWords, id: \.self) { word in
                                Button(action: {
                                    onSelectWord(word)
                                }) {
                                    Text(word)
                                        .font(.caption2.weight(.medium))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(Color(.tertiarySystemFill))
                                        .foregroundColor(.primary)
                                        .cornerRadius(5)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 2)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                if let examples = meaning.orneklerListe, let eg = examples.first {
                    Text("“\(eg.ornek)”")
                        .font(.callout)
                        .italic()
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                        .padding(.top, 2)
                }
            }
        }
    }

    private var meaningWords: [String] {
        let tokens = meaning.anlam.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
        var words: [String] = []
        let punctuation = CharacterSet.punctuationCharacters.union(.symbols)
        for token in tokens {
            let clean = token.trimmingCharacters(in: punctuation)
            if clean.count >= 2 && !words.contains(clean) {
                words.append(clean)
            }
        }
        return words
    }
}
