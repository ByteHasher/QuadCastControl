//
//  ColorPreset.swift
//  QuadCastControl
//
//  Created by ByteHasher on 19.10.2026.
//

import Foundation

nonisolated enum ColorPreset: String, CaseIterable, Identifiable, Sendable {
    case red, orange, yellow, green, cyan, blue, purple, white

    var id: String { rawValue }

    var color: RGBColor {
        switch self {
        case .red: RGBColor(red: 255, green: 0, blue: 0)
        case .orange: RGBColor(red: 255, green: 128, blue: 0)
        case .yellow: RGBColor(red: 255, green: 255, blue: 0)
        case .green: RGBColor(red: 0, green: 255, blue: 0)
        case .cyan: RGBColor(red: 0, green: 255, blue: 255)
        case .blue: RGBColor(red: 0, green: 0, blue: 255)
        case .purple: RGBColor(red: 179, green: 0, blue: 255)
        case .white: RGBColor(red: 255, green: 255, blue: 255)
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .red: "lighting.preset.red"
        case .orange: "lighting.preset.orange"
        case .yellow: "lighting.preset.yellow"
        case .green: "lighting.preset.green"
        case .cyan: "lighting.preset.cyan"
        case .blue: "lighting.preset.blue"
        case .purple: "lighting.preset.purple"
        case .white: "lighting.preset.white"
        }
    }
}
