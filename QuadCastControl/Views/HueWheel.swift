//
//  HueWheel.swift
//  QuadCastControl
//
//  Created by ByteHasher on 19.10.2026.
//

import AppKit
import SwiftUI

struct HueWheel: View {
    @Binding var color: RGBColor
    @Environment(\.isEnabled) private var enabled

    private var components: (hue: Double, saturation: Double, brightness: Double) {
        let value = NSColor(srgbRed: Double(color.red) / 255, green: Double(color.green) / 255,
                            blue: Double(color.blue) / 255, alpha: 1)
        return (Double(value.hueComponent), Double(value.saturationComponent), Double(value.brightnessComponent))
    }

    var body: some View {
        VStack(spacing: 15) {
            GeometryReader { geometry in
                let diameter = min(geometry.size.width, geometry.size.height)
                let center = diameter / 2
                let radius = center - 10
                let angle = components.hue * 2 * .pi
                ZStack {
                    Circle().strokeBorder(AngularGradient(colors: (0...36).map {
                        Color(hue: Double($0) / 36, saturation: 1, brightness: 1)
                    }, center: .center), lineWidth: 20)
                    Circle().fill(color.swiftUIColor).frame(width: diameter * 0.39, height: diameter * 0.39)
                        .overlay(Circle().stroke(WorkspaceTheme.line, lineWidth: 1))
                    Circle().fill(color.swiftUIColor).overlay(Circle().stroke(WorkspaceTheme.selectionRing, lineWidth: 2))
                        .frame(width: 20, height: 20).shadow(color: .black.opacity(0.4), radius: 3, y: 1)
                        .position(x: center + cos(angle) * radius, y: center + sin(angle) * radius)
                }
                .frame(width: diameter, height: diameter).contentShape(Circle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                    guard enabled else { return }
                    let angle = atan2(value.location.y - center, value.location.x - center)
                    update(hue: (angle + 2 * .pi).truncatingRemainder(dividingBy: 2 * .pi) / (2 * .pi),
                           saturation: components.saturation > 0.01 ? components.saturation : 1)
                })
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("workspace.hue")
                .accessibilityValue(Text(components.hue * 360, format: .number.precision(.fractionLength(0))))
                .accessibilityAdjustableAction { direction in
                    guard enabled else { return }
                    let delta = direction == .increment ? 1.0 / 36 : -1.0 / 36
                    update(hue: (components.hue + delta + 1).truncatingRemainder(dividingBy: 1),
                           saturation: components.saturation > 0.01 ? components.saturation : 1)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("workspace.saturation").font(.system(size: 10)).foregroundStyle(WorkspaceTheme.muted)
                Slider(value: Binding(get: { components.saturation }, set: {
                    update(hue: components.hue, saturation: $0)
                }), in: 0...1).controlSize(.mini).accessibilityLabel("workspace.saturation")
            }
        }
        .opacity(enabled ? 1 : 0.4)
    }

    private func update(hue: Double, saturation: Double) {
        let value = Color(hue: hue, saturation: saturation, brightness: components.brightness > 0.01 ? components.brightness : 1)
        if let rgb = RGBColor(swiftUIColor: value) { color = rgb }
    }
}
