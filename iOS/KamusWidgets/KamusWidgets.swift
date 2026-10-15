import WidgetKit
import SwiftUI

@main
struct KamusWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WordOfTheDayWidget()
        QuickSearchWidget()
    }
}
