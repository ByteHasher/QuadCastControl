import SwiftUI

struct AppLanguageView<Content: View>: View {
    @AppStorage(AppLanguage.storageKey) private var language = AppLanguage.system
    @ViewBuilder var content: Content

    var body: some View {
        content.environment(\.locale, language.resolvedLocale())
    }
}
