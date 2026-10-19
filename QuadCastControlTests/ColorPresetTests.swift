import Foundation
import Testing
@testable import QuadCastControl

struct ColorPresetTests {
    @Test func presetsHaveExactDeviceRGBValues() {
        #expect(ColorPreset.allCases.map(\.color) == [
            RGBColor(red: 255, green: 0, blue: 0),
            RGBColor(red: 255, green: 128, blue: 0),
            RGBColor(red: 255, green: 255, blue: 0),
            RGBColor(red: 0, green: 255, blue: 0),
            RGBColor(red: 0, green: 255, blue: 255),
            RGBColor(red: 0, green: 0, blue: 255),
            RGBColor(red: 179, green: 0, blue: 255),
            RGBColor(red: 255, green: 255, blue: 255)
        ])
    }

    @Test func everyPresetHasItsOwnCatalogKey() {
        #expect(ColorPreset.allCases.map { $0.title.key } == [
            "lighting.preset.red", "lighting.preset.orange", "lighting.preset.yellow",
            "lighting.preset.green", "lighting.preset.cyan", "lighting.preset.blue",
            "lighting.preset.purple", "lighting.preset.white"
        ])
    }
}
