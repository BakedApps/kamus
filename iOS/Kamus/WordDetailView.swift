import SwiftUI
import UIKit

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

// MARK: - Kenar boşluğu
// iPhone Duo'da dikey bar tek kenarda duruyor; sistem yalnızca o kenara emniyet
// payı veriyor, karşı kenar ekranın kıyısına yapışıyor. Cihaz katlanınca geometri
// değiştiği için pencereyi bir görünüm üzerinden gözlemleyerek oku.
@MainActor
final class KamusMetrics: ObservableObject {
    static let shared = KamusMetrics()

    @Published private(set) var top: CGFloat = 0
    @Published private(set) var leading: CGFloat = 0
    @Published private(set) var trailing: CGFloat = 0
    @Published private(set) var width: CGFloat = 0

    // Duo'nun dikey barı tek kenarda paya bırakıyor (ölçülen: L0 R84). Normal
    // iPhone'da iki kenar da paylıdır; oraya karışma.
    private var hasSideGutter: Bool {
        min(leading, trailing) == 0 && max(leading, trailing) >= 40
    }

    // Duo'da sistem üst emniyet payını 0 bırakıyor, başlık ekranın kıyısına
    // yapışmasın.
    var topBreathing: CGFloat {
        top == 0 && hasSideGutter ? 28 : 0
    }

    // Kolon ayracı mafsalın üstüne, yani ekranın tam yarısına otursun.
    var sidebarWidth: CGFloat {
        min(max(width / 2, 260), 500)
    }

    func update(insets: UIEdgeInsets, size: CGSize) {
        guard insets.top != top || insets.left != leading || insets.right != trailing || size.width != width
        else { return }
        top = insets.top
        leading = insets.left
        trailing = insets.right
        width = size.width
    }
}

private final class KamusGeometryProbeView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let window else { return }
        let insets = window.safeAreaInsets
        let size = window.bounds.size
        Task { @MainActor in KamusMetrics.shared.update(insets: insets, size: size) }
    }
}

private struct KamusGeometryProbe: UIViewRepresentable {
    func makeUIView(context: Context) -> KamusGeometryProbeView { KamusGeometryProbeView() }
    func updateUIView(_ uiView: KamusGeometryProbeView, context: Context) {
        uiView.setNeedsLayout()
    }
}

private struct KamusEdgePadding: ViewModifier {
    @ObservedObject private var metrics = KamusMetrics.shared

    func body(content: Content) -> some View {
        content
            // Sabit 16pt: sistem listelerinin payasıyla aynı, ekranlar arasında kaymıyor.
            .padding(.horizontal, 16)
            .padding(.top, metrics.topBreathing)
            .background(KamusGeometryProbe())
    }
}

private struct KamusSidebarWidth: ViewModifier {
    @ObservedObject private var metrics = KamusMetrics.shared

    func body(content: Content) -> some View {
        content.navigationSplitViewColumnWidth(min: 260, ideal: metrics.sidebarWidth, max: metrics.sidebarWidth)
    }
}

extension View {
    func kamusEdgePadding() -> some View {
        modifier(KamusEdgePadding())
    }

    // Sidebar kolonunu Duo'nun mafsasına (ekranın yarısına) hizala.
    func kamusSidebarWidth() -> some View {
        modifier(KamusSidebarWidth())
    }
}

// MARK: - Kart görünümü (künye ve anlamlar tek başına da kullanılabilsin)
extension View {
    func kamusCard() -> some View {
        // Önerilen genişliği doldur; yoksa kısa anlamlı kart içerik kadar kalıyor.
        frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Word Detail Card View (künye + anlamlar, tek kart)
struct WordDetailCardView: View {
    let wordResult: WordResult
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    var onSelectWord: ((String) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            WordIdentityView(
                wordResult: wordResult,
                isFavorite: isFavorite,
                onToggleFavorite: onToggleFavorite
            )

            Divider()

            WordMeaningsView(wordResult: wordResult, onSelectWord: onSelectWord)
        }
        .kamusCard()
    }
}

// MARK: - Anlam kolonu (regular genişliğin sağ pane'i: ortalanmış, kaplı kart)
struct MeaningDetailCard: View {
    let wordResult: WordResult
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    var onSelectWord: ((String) -> Void)? = nil

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                WordDetailCardView(
                    wordResult: wordResult,
                    isFavorite: isFavorite,
                    onToggleFavorite: onToggleFavorite,
                    onSelectWord: onSelectWord
                )
                // Dikey ScrollView genişlik önermediği için kartı pane genişliğine
                // bağla; geniş iç ekranda satırı okunur seviyede tut.
                .frame(width: min(proxy.size.width - 32, 700))
                .frame(width: proxy.size.width)
                .padding(.vertical, 16)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Seçili kelimenin anlam kolonu (tüm sekmelerin sağ pane'i)
struct SelectedWordDetailPane: View {
    @EnvironmentObject var searchVM: MobileSearchViewModel
    var emptyTitle: String
    var emptyDescription: String

    var body: some View {
        Group {
            if let result = searchVM.selectedResult {
                MeaningDetailCard(
                    wordResult: result,
                    isFavorite: searchVM.isCurrentWordFavorite,
                    onToggleFavorite: { searchVM.toggleFavorite(word: result.madde) },
                    onSelectWord: { searchVM.search(word: $0) }
                )
            } else if searchVM.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: "text.magnifyingglass",
                    description: Text(emptyDescription)
                )
            }
        }
        // Detay kolonunun varsayılan zemini beyaz; seçim yokken de gri kalsın.
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Kelime Künyesi (başlık, dil, ses/favori/paylaş)
struct WordIdentityView: View {
    let wordResult: WordResult
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    @StateObject private var speaker = TurkishSpeechSpeaker.shared

    // Dar sidebar'da (≈260pt) butonlar başlığın üstüne biniyor; sığmıyorsa
    // künye bloğu ile eylemleri alt alta diz.
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 12) {
                identityBlock
                Spacer(minLength: 8)
                actionButtons
            }

            VStack(alignment: .leading, spacing: 12) {
                identityBlock
                actionButtons
            }
        }
    }

    private var identityBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(wordResult.madde)
                .font(.system(.title, design: .serif, weight: .bold))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                // Dar dış ekranda başlığın hecelere bölünmesindense küçülmesi iyi.
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .layoutPriority(1)

            if !wordResult.lisan.isEmpty {
                Text(wordResult.lisan)
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
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

// MARK: - Anlamlar (birleşik sözler + madde madde anlam/örnek)
struct WordMeaningsView: View {
    let wordResult: WordResult
    var onSelectWord: ((String) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                                        .font(.caption2)
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

            // Anlamsız üst kenar çizgisi kalmasın: ayraç yalnızca çiplerin altında.
            if !compoundWords.isEmpty {
                Divider()
            }

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
    }

    private var compoundWords: [String] {
        guard !wordResult.birlesikler.isEmpty else { return [] }
        return wordResult.birlesikler
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
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
                    .frame(minWidth: 22, alignment: .leading)

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
                                    .font(.caption)
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
