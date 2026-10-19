import AppKit
import SwiftUI

extension RGBColor {
    var swiftUIColor: Color {
        Color(.sRGB, red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    }

    /// Only custom ColorPicker input needs conversion back into byte-valued sRGB.
    init?(swiftUIColor: Color) {
        guard let color = NSColor(swiftUIColor).usingColorSpace(.sRGB),
              color.redComponent.isFinite, color.greenComponent.isFinite,
              color.blueComponent.isFinite else { return nil }
        func channel(_ value: CGFloat) -> UInt8 {
            UInt8((min(max(value, 0), 1) * 255).rounded())
        }
        self.init(red: channel(color.redComponent), green: channel(color.greenComponent), blue: channel(color.blueComponent))
    }
}
