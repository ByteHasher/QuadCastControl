import SwiftUI

extension AppAppearance {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Observe the preference inside each window, keeping the workspace's identity
/// and its device sessions intact when appearance changes.
struct AppAppearanceView<Content: View>: View {
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.system
    @Environment(\.colorScheme) private var systemColorScheme
    @ViewBuilder var content: Content

    var body: some View {
        content
            .environment(\.colorScheme, appearance.colorScheme ?? systemColorScheme)
            .preferredColorScheme(appearance.colorScheme)
    }
}
