import SwiftUI
import Testing
@testable import QuadCastControl

@MainActor
struct RGBColorSwiftUITests {
    @Test func displayingEveryPresetPreservesItsExactByteColor() {
        for preset in ColorPreset.allCases {
            #expect(RGBColor(swiftUIColor: preset.color.swiftUIColor) == preset.color)
        }
    }

    @Test func customPickerInputUsesDefinedNearestByteRounding() {
        // Binary-exact input tests rounding without relying on decimal float storage.
        let input = Color(.sRGB, red: 0.5, green: 0.25, blue: 1)
        #expect(RGBColor(swiftUIColor: input) == RGBColor(red: 128, green: 64, blue: 255))
    }
}
