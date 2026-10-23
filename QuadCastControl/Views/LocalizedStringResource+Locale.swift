import Foundation

extension LocalizedStringResource {
    /// Resources capture a locale when created; use the workspace's selected
    /// language for model-provided titles, help and accessibility text as well.
    func localized(for locale: Locale) -> LocalizedStringResource {
        var resource = self
        resource.locale = locale
        return resource
    }
}
