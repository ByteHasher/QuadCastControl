import AppKit
import Observation
import SwiftUI
import Testing
@testable import QuadCastControl

@MainActor
struct AppAppearanceTests {
    @Test func selectionUpdatesExistingContentAndSystemModeFollowsItsEnvironment() async throws {
        let suite = "QuadCastControl.AppearanceTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let system = SystemAppearance()
        let observation = AppearanceObservation()
        let host = NSHostingView(rootView:
            AppearanceHarness(system: system, observation: observation).defaultAppStorage(defaults))
        host.frame = NSRect(x: 0, y: 0, width: 40, height: 40)

        // One host for the entire test. Do not set its AppKit appearance or
        // replace rootView: either would hide a broken in-app preference.
        try await expect(.light, backgroundRed: 245 / 255, in: host, observation: observation)
        let identity = observation.identity
        defaults.set(AppAppearance.dark.rawValue, forKey: AppAppearance.storageKey)
        try await expect(.dark, backgroundRed: 27 / 255, in: host, observation: observation)
        defaults.set(AppAppearance.light.rawValue, forKey: AppAppearance.storageKey)
        try await expect(.light, backgroundRed: 245 / 255, in: host, observation: observation)
        system.scheme = .dark
        try await expect(.light, backgroundRed: 245 / 255, in: host, observation: observation)
        defaults.set(AppAppearance.system.rawValue, forKey: AppAppearance.storageKey)
        try await expect(.dark, backgroundRed: 27 / 255, in: host, observation: observation)
        system.scheme = .light
        try await expect(.light, backgroundRed: 245 / 255, in: host, observation: observation)
        #expect(observation.identity == identity, "Theme changes must preserve workspace state")
    }

    private func expect<Content: View>(_ scheme: ColorScheme, backgroundRed: Float,
                                      in host: NSHostingView<Content>,
                                      observation: AppearanceObservation) async throws {
        for _ in 0..<100 {
            host.layoutSubtreeIfNeeded()
            if observation.scheme == scheme,
               let red = observation.backgroundRed, abs(red - backgroundRed) < 0.005 { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(observation.scheme == scheme)
        #expect(abs((observation.backgroundRed ?? -1) - backgroundRed) < 0.005)
    }
}

@MainActor @Observable
private final class SystemAppearance {
    var scheme = ColorScheme.light
}

@MainActor
private final class AppearanceObservation {
    var scheme: ColorScheme?
    var backgroundRed: Float?
    var identity: UUID?

    func record(environment: EnvironmentValues, identity: UUID) {
        scheme = environment.colorScheme
        backgroundRed = WorkspaceTheme.background.resolve(in: environment).red
        self.identity = identity
    }
}

private struct AppearanceHarness: View {
    let system: SystemAppearance
    let observation: AppearanceObservation

    var body: some View {
        AppAppearanceView { AppearanceProbe(observation: observation) }
            .environment(\.colorScheme, system.scheme)
    }
}

private struct AppearanceProbe: View {
    @Environment(\.self) private var environment
    @State private var identity = UUID()
    let observation: AppearanceObservation

    var body: some View {
        observation.record(environment: environment, identity: identity)
        return WorkspaceTheme.background
    }
}
