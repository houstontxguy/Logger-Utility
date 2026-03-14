import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab = 0
}
