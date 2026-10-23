import AppKit
import SwiftUI
import Testing
@testable import QuadCastControl

@MainActor
struct AppLanguageTests {
    @Test func explicitLanguageOverridesSystemPreferences() {
        #expect(AppLanguage.english.resolvedLocale(preferredLanguages: ["ru-RU"]).identifier == "en")
        #expect(AppLanguage.russian.resolvedLocale(preferredLanguages: ["en-US"]).identifier == "ru")
    }

    @Test func systemUsesSupportedPreferredLanguagesAndFallsBackToEnglish() {
        #expect(AppLanguage.system.resolvedLocale(preferredLanguages: ["ru-RU", "en-US"]).identifier == "ru")
        #expect(AppLanguage.system.resolvedLocale(preferredLanguages: ["en-GB", "ru-RU"]).identifier == "en")
        #expect(AppLanguage.system.resolvedLocale(preferredLanguages: ["es-ES", "ru-RU"]).identifier == "ru")
        #expect(AppLanguage.system.resolvedLocale(preferredLanguages: ["fr-FR"]).identifier == "en")
    }

    @Test func selectionDefaultsToSystemAndSurvivesReopeningPreferences() throws {
        let suite = "QuadCastControl.LanguagePersistence." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let setting = AppStorage(wrappedValue: AppLanguage.system, AppLanguage.storageKey, store: defaults)
        #expect(setting.wrappedValue == .system)
        for language in AppLanguage.allCases {
            setting.wrappedValue = language
            let reopened = AppStorage(wrappedValue: AppLanguage.system, AppLanguage.storageKey,
                                      store: try #require(UserDefaults(suiteName: suite)))
            #expect(reopened.wrappedValue == language)
        }
    }

    @Test func resourcesUseTheSelectedLanguageEvenWhenCreatedInAnotherLocale() {
        let english = Locale(identifier: "en")
        let russian = Locale(identifier: "ru")
        var resource = DeviceTab.overview.title
        resource.locale = english
        #expect(String(localized: resource.localized(for: russian)) == "Обзор")
        #expect(String(localized: resource.localized(for: english)) == "Overview")
        #expect(String(localized: AppAppearance.dark.title.localized(for: russian)) == "Тёмная")
        #expect(String(localized: ColorPreset.red.title.localized(for: russian)) == "Красный")
        #expect(String(localized: LightingFailure.disconnected.message.localized(for: russian)) !=
                String(localized: LightingFailure.disconnected.message.localized(for: english)))
    }

    @Test func changingLanguageUpdatesExistingContentWithoutResettingItsState() async throws {
        let suite = "QuadCastControl.LanguageSwitching." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let observation = LanguageObservation()
        let host = NSHostingView(rootView:
            AppLanguageView { LanguageProbe(observation: observation) }.defaultAppStorage(defaults))
        host.frame = NSRect(x: 0, y: 0, width: 80, height: 40)

        for language in [AppLanguage.english, .russian, .english, .system] {
            defaults.set(language.rawValue, forKey: AppLanguage.storageKey)
            let expected = language.resolvedLocale().identifier
            for _ in 0..<100 {
                host.layoutSubtreeIfNeeded()
                if observation.locale == expected { break }
                try await Task.sleep(for: .milliseconds(10))
            }
            #expect(observation.locale == expected)
            #expect(observation.title == (expected == "ru" ? "Обзор" : "Overview"))
            #expect(observation.identities.count == 1, "Language changes must preserve workspace state")
        }
    }
}

@MainActor
private final class LanguageObservation {
    var locale: String?
    var title: String?
    var identities: Set<UUID> = []

    func record(locale: Locale, identity: UUID) {
        self.locale = locale.identifier
        title = String(localized: DeviceTab.overview.title.localized(for: locale))
        identities.insert(identity)
    }
}

private struct LanguageProbe: View {
    @Environment(\.locale) private var locale
    @State private var identity = UUID()
    let observation: LanguageObservation

    var body: some View {
        observation.record(locale: locale, identity: identity)
        return Text(DeviceTab.overview.title.localized(for: locale))
    }
}
