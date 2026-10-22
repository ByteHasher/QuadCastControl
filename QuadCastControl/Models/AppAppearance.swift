import Foundation

nonisolated enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case system, light, dark

    static let storageKey = "appearanceMode"
    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .system: "appearance.system"
        case .light: "appearance.light"
        case .dark: "appearance.dark"
        }
    }
}
