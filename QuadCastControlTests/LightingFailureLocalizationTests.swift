import Foundation
import Testing
@testable import QuadCastControl

struct LightingFailureLocalizationTests {
    @Test func eachFailureUsesTheMatchingCatalogMessage() {
        let failures: [LightingFailure] = [
            .unavailable, .openFailed, .unsupported, .accessDenied, .disconnected, .transferFailed
        ]
        #expect(failures.map { $0.message.key } == [
            "lighting.unavailable", "lighting.openFailed", "lighting.unsupported",
            "lighting.accessDenied", "lighting.disconnected", "lighting.transferFailed"
        ])
    }
}
