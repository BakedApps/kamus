import SwiftUI

struct WordDetailCardView: View {
    let wordResult: WordResult
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    @StateObject private var speaker = TurkishSpeechSpeaker.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Kelime Başlığı, Telaffuz, Favori, Paylaş
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(wordResult.madde)
                        .font(.system(.title, design: .serif, weight: .bold))
                        .foregroundColor(.primary)

                    if !wordResult.lisan.isEmpty {
                        Text(wordResult.lisan)
                            .font(.subheadline)
                            .italic()
                            .foregroundColor(.secondary)
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

            // Birleşik Kelimeler
            if !wordResult.birlesikler.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("BİRLEŞİK SÖZLER")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.secondary)
                        .tracking(0.5)

                    Text(wordResult.birlesikler)
                        .font(.footnote)
                        .foregroundColor(.primary.opacity(0.85))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
            }

            Divider()

            // Anlamlar Listesi
            VStack(alignment: .leading, spacing: 14) {
                ForEach(wordResult.anlamlarListe.indices, id: \.self) { index in
                    let meaning = wordResult.anlamlarListe[index]
                    MeaningRowView(meaning: meaning, index: index + 1)
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
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

struct MeaningRowView: View {
    let meaning: Meaning
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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

                    // Anlam Metni
                    Text(meaning.anlam)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Örnek Cümleler
                    if let examples = meaning.orneklerListe, !examples.isEmpty {
                        ForEach(examples, id: \.ornek_id) { eg in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("“\(eg.ornek)”")
                                    .font(.callout)
                                    .italic()
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 6)
                            .padding(.top, 2)
                        }
                    }
                }
            }
        }
    }
}
