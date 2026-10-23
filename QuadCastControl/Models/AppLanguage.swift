import Foundation

nonisolated enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case english = "en"
    case russian = "ru"

    static let storageKey = "appLanguage"
    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .system: "language.system"
        case .english: "language.english"
        case .russian: "language.russian"
        }
    }

    func resolvedLocale(preferredLanguages: [String] = Locale.preferredLanguages) -> Locale {
        let identifier = self == .system
            ? Bundle.preferredLocalizations(from: ["en", "ru"], forPreferences: preferredLanguages).first ?? "en"
            : rawValue
        return Locale(identifier: identifier)
    }
}
