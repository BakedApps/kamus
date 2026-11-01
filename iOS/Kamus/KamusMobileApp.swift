import SwiftUI

@main
struct KamusMobileApp: App {
    @StateObject private var searchVM = MobileSearchViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainTabView()
                // Duo'nun dikey bar payası gibi içerik dışı şeritler beyaz kalmasın.
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
                .environmentObject(searchVM)
                .onOpenURL { url in
                    handleDeepLink(url: url)
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        searchVM.checkClipboardForWord()
                    }
                }
        }
    }

    private func handleDeepLink(url: URL) {
        guard url.scheme == "kamus" else { return }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryWord = components?.queryItems?.first(where: { $0.name == "q" })?.value

        if let queryWord = queryWord?.trimmingCharacters(in: .whitespacesAndNewlines), !queryWord.isEmpty {
            searchVM.selectedTab = .search
            searchVM.search(word: queryWord)
        }
    }
}

enum MobileTab: Int, CaseIterable, Identifiable {
    case search = 0
    case wordOfDay = 1
    case favorites = 2
    case history = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .search: return "Ara"
        case .wordOfDay: return "Günün Kelimesi"
        case .favorites: return "Favoriler"
        case .history: return "Geçmiş"
        }
    }

    var icon: String {
        switch self {
        case .search: return "magnifyingglass"
        case .wordOfDay: return "sparkles"
        case .favorites: return "star.fill"
        case .history: return "clock.arrow.circlepath"
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var searchVM: MobileSearchViewModel

    var body: some View {
        TabView(selection: $searchVM.selectedTab) {
            HomeSearchView()
                .tabItem {
                    Label(MobileTab.search.title, systemImage: MobileTab.search.icon)
                }
                .tag(MobileTab.search)

            WordOfTheDayView()
                .tabItem {
                    Label(MobileTab.wordOfDay.title, systemImage: MobileTab.wordOfDay.icon)
                }
                .tag(MobileTab.wordOfDay)

            FavoritesView()
                .tabItem {
                    Label(MobileTab.favorites.title, systemImage: MobileTab.favorites.icon)
                }
                .tag(MobileTab.favorites)

            HistoryView()
                .tabItem {
                    Label(MobileTab.history.title, systemImage: MobileTab.history.icon)
                }
                .tag(MobileTab.history)
        }
        .tint(Color.accentColor)
    }
}
