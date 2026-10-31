import WidgetKit
import SwiftUI

struct QuickSearchEntry: TimelineEntry {
    let date: Date
}

struct QuickSearchTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickSearchEntry {
        QuickSearchEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickSearchEntry) -> Void) {
        completion(QuickSearchEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickSearchEntry>) -> Void) {
        let timeline = Timeline(entries: [QuickSearchEntry(date: Date())], policy: .never)
        completion(timeline)
    }
}

struct QuickSearchWidget: Widget {
    let kind: String = "QuickSearchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickSearchTimelineProvider()) { entry in
            QuickSearchWidgetView()
        }
        .configurationDisplayName("Hızlı Arama")
        .description("Kâmus'ta tek dokunuşla kelime arayın.")
        .supportedFamilies([
            .systemSmall,
            .accessoryCircular,
            .accessoryInline
        ])
    }
}

struct QuickSearchWidgetView: View {
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image("KamusLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .accessibilityHidden(true)
                    Spacer()
                }

                Spacer()

                Text("Kâmus")
                    .font(.system(.headline, design: .serif, weight: .bold))

                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption2)
                    Text("Kelime Ara")
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentColor.opacity(0.12))
                .cornerRadius(8)
            }
            .padding(12)
            .containerBackground(for: .widget) {
                Color(.secondarySystemGroupedBackground)
            }
            .widgetURL(URL(string: "kamus://search"))

        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image("KamusMark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
            }
            .widgetURL(URL(string: "kamus://search"))

        case .accessoryInline:
            Label("Kâmus'ta Ara", systemImage: "magnifyingglass")
                .widgetURL(URL(string: "kamus://search"))

        default:
            EmptyView()
        }
    }
}
