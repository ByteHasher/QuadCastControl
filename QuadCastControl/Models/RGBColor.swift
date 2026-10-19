//
//  RGBColor.swift
//  QuadCastControl
//
//  Created by ByteHasher on 19.10.2026.
//

nonisolated struct RGBColor: Equatable, Sendable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8

    static let off = RGBColor(red: 0, green: 0, blue: 0)

    /// Scales channels by a percentage clamped to 0...100, rounding to nearest
    /// with exact halves rounded up. Application logic, not a hardware command.
    func scaled(byPercent percent: Int) -> RGBColor {
        let p = UInt16(min(max(percent, 0), 100))
        func scale(_ channel: UInt8) -> UInt8 {
            UInt8((UInt16(channel) * p + 50) / 100)
        }
        return RGBColor(red: scale(red), green: scale(green), blue: scale(blue))
    }
}
