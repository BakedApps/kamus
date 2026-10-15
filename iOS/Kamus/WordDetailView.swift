import SwiftUI

// MARK: - Modern Wrapping Flow Layout (iOS 16+)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

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

// MARK: - Word Detail Card View
struct WordDetailCardView: View {
    let wordResult: WordResult
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    var onSelectWord: ((String) -> Void)? = nil

    @StateObject private var speaker = TurkishSpeechSpeaker.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Kelime Başlığı, Telaffuz, Favori, Paylaş
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(wordResult.madde)
                        .font(.system(.title, design: .serif, weight: .bold))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)

                    if !wordResult.lisan.isEmpty {
                        Text(wordResult.lisan)
                            .font(.subheadline)
                            .italic()
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                }

                Spacer()

                // Sesli Telaffuz Butonu
                Button(action: {
                    speaker.speak(wordResult.madde)
                }) {
                    Image(systemName: speaker.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .padding(8)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Kelimeyi dinle")

                // Favori Butonu
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundColor(isFavorite ? .yellow : .secondary)
                        .padding(8)
                        .background((isFavorite ? Color.yellow : Color.secondary).opacity(0.12))
                        .clipShape(Circle())
                }
                .accessibilityLabel(isFavorite ? "Favorilerden çıkar" : "Favorilere ekle")

                // Paylaş Butonu
                ShareLink(item: shareSummary) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Kelimeyi paylaş")
            }

            // Birleşik Kelimeler (Tıklanabilir ve aranabilir interaktif çipler)
            if !compoundWords.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("BİRLEŞİK SÖZLER")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                        Spacer()
                        Text("Aramak için dokunun")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.7))
                    }

                    FlowLayout(spacing: 6) {
                        ForEach(compoundWords, id: \.self) { compound in
                            Button(action: {
                                onSelectWord?(compound)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 9))
                                    Text(compound)
                                        .font(.footnote.weight(.medium))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.accentColor.opacity(0.08))
                                .foregroundColor(.accentColor)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Divider()

            // Anlamlar Listesi
            VStack(alignment: .leading, spacing: 16) {
                ForEach(wordResult.anlamlarListe.indices, id: \.self) { index in
                    let meaning = wordResult.anlamlarListe[index]
                    MeaningRowView(
                        meaning: meaning,
                        index: index + 1,
                        onSelectWord: onSelectWord
                    )
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    private var compoundWords: [String] {
        guard !wordResult.birlesikler.isEmpty else { return [] }
        return wordResult.birlesikler
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var shareSummary: String {
        var text = "\(wordResult.madde)"
        if !wordResult.lisan.isEmpty {
            text += " (\(wordResult.lisan))"
        }
        text += "\n"
        for (i, m) in wordResult.anlamlarListe.enumerated() {
            text += "\n\(i + 1). \(m.anlam)"
            if let examples = m.orneklerListe, let first = examples.first {
                text += "\n   \"\(first.ornek)\""
            }
        }
        text += "\n\n— Kâmus Türkçe Sözlük"
        return text
    }
}

// MARK: - Meaning Row View
struct MeaningRowView: View {
    let meaning: Meaning
    let index: Int
    var onSelectWord: ((String) -> Void)? = nil

    @State private var isWordExplorerOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text("\(index).")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 22, alignment: .leading)

                VStack(alignment: .leading, spacing: 6) {
                    // Özellik rozetleri (isim, sıfat, mecaz vb.)
                    if let props = meaning.ozelliklerListe, !props.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(props, id: \.ozellik_id) { prop in
                                Text(prop.tam_adi.lowercased())
                                    .font(.caption2.weight(.medium))
                                    .foregroundColor(.accentColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }

                    // Anlam Metni (Metin seçilebilir)
                    Text(meaning.anlam)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)

                    // Kelime Keşfet Butonu & Çipleri
                    if !meaningWords.isEmpty {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isWordExplorerOpen.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isWordExplorerOpen ? "chevron.up.circle.fill" : "text.magnifyingglass")
                                    .font(.system(size: 11))
                                Text(isWordExplorerOpen ? "Kelimeleri Gizle" : "Anlamdaki Kelimeleri Ara")
                                    .font(.caption2.weight(.medium))
                            }
                            .foregroundColor(.accentColor)
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)

                        if isWordExplorerOpen {
                            FlowLayout(spacing: 6) {
                                ForEach(meaningWords, id: \.self) { word in
                                    Button(action: {
                                        onSelectWord?(word)
                                    }) {
                                        Text(word)
                                            .font(.caption2.weight(.medium))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(.tertiarySystemFill))
                                            .foregroundColor(.primary)
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 2)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    // Örnek Cümleler
                    if let examples = meaning.orneklerListe, !examples.isEmpty {
                        ForEach(examples, id: \.ornek_id) { eg in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("“\(eg.ornek)”")
                                    .font(.callout)
                                    .italic()
                                    .foregroundColor(.secondary)
                                    .textSelection(.enabled)
                            }
                            .padding(.leading, 6)
                            .padding(.top, 4)
                        }
                    }
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
