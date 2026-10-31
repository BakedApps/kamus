import WidgetKit
import SwiftUI

struct WordOfTheDayEntry: TimelineEntry {
    let date: Date
    let word: String
    let language: String
    let meaning: String
    let example: String?
}

struct WordOfTheDayTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WordOfTheDayEntry {
        WordOfTheDayEntry(
            date: Date(),
            word: "müstesna",
            language: "Arapça",
            meaning: "Benzerlerinden ayrılan, ayrı tutulan, kural dışı.",
            example: "Herkes gibi davranmayan, müstesna bir insandı."
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WordOfTheDayEntry) -> Void) {
        Task {
            let entry = await fetchEntry(for: Date())
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordOfTheDayEntry>) -> Void) {
        Task {
            let now = Date()
            let entry = await fetchEntry(for: now)

            // Gece yarısı bir sonraki güne geçildiğinde yenile
            let cal = Calendar.current
            let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) ?? now.addingTimeInterval(86400)
            let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
            completion(timeline)
        }
    }

    private func fetchEntry(for date: Date) async -> WordOfTheDayEntry {
        if let item = await DictionaryStore.shared.wordOfTheDay(for: date),
           let first = item.response.results.first,
           let meaning = first.anlamlarListe.first {
            let exampleText = meaning.orneklerListe?.first?.ornek
            return WordOfTheDayEntry(
                date: date,
                word: first.madde,
                language: first.lisan,
                meaning: meaning.anlam,
                example: exampleText
            )
        }

        return WordOfTheDayEntry(
            date: date,
            word: "kâmus",
            language: "Arapça",
            meaning: "Sözlük, lügat; bir dilin bütün veya belirli bir dönemdeki kelime hazinesi.",
            example: "Kâmus bir milletin hafızasıdır."
        )
    }
}

struct WordOfTheDayWidget: Widget {
    let kind: String = "WordOfTheDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WordOfTheDayTimelineProvider()) { entry in
            WordOfTheDayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Günün Kelimesi")
        .description("Her gün yeni bir Türkçe kelime ve anlamını keşfedin.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryCircular
        ])
    }
}

struct WordOfTheDayWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: WordOfTheDayEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
                .widgetURL(deepLinkURL)
        case .systemMedium:
            mediumView
                .widgetURL(deepLinkURL)
        case .accessoryRectangular:
            lockScreenRectangularView
                .widgetURL(deepLinkURL)
        case .accessoryCircular:
            lockScreenCircularView
                .widgetURL(deepLinkURL)
        default:
            mediumView
                .widgetURL(deepLinkURL)
        }
    }

    private var deepLinkURL: URL? {
        URL(string: "kamus://search?q=\(entry.word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? entry.word)")
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("GÜNÜN KELİMESİ")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.accentColor)
                    .tracking(0.6)
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundColor(.accentColor)
            }

            Spacer()

            Text(entry.word)
                .font(.system(.title3, design: .serif, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)

            if !entry.language.isEmpty {
                Text(entry.language)
                    .font(.system(size: 10))
                    .italic()
                    .foregroundColor(.secondary)
            }

            Text(entry.meaning)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color(.secondarySystemGroupedBackground)
        }
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("GÜNÜN KELİMESİ", systemImage: "sparkles")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.accentColor)
                    .tracking(0.6)

                Spacer()

                Text("Kâmus")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(entry.word)
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundColor(.primary)

                if !entry.language.isEmpty {
                    Text(entry.language)
                        .font(.caption)
                        .italic()
                        .foregroundColor(.secondary)
                }
            }

            Text(entry.meaning)
                .font(.subheadline)
                .foregroundColor(.primary.opacity(0.85))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if let eg = entry.example, !eg.isEmpty {
                Text("“\(eg)”")
                    .font(.caption)
                    .italic()
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(.secondarySystemGroupedBackground)
        }
    }

    private var lockScreenRectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.word)
                .font(.headline)
                .lineLimit(1)
            Text(entry.meaning)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
    }

    private var lockScreenCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image("KamusMark")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
        }
    }
}
