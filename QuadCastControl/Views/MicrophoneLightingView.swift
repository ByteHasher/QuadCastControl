//
//  MicrophoneLightingView.swift
//  QuadCastControl
//
//  Created by ByteHasher on 19.10.2026.
//

import SwiftUI

struct MicrophoneLightingView: View {
    let microphone: Microphone
    @Bindable var lighting: LightingControl
    @State private var selectedColor = RGBColor(red: 0, green: 160, blue: 255)
    @State private var brightness = 100.0
    @State private var colorEnabled = true

    private var state: LightingState { lighting.states[microphone.id] ?? .idle }
    private var unavailable: Bool { microphone.usbIdentity == nil || state == .stopping }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ColorPicker("lighting.color", selection: colorSelection, supportsOpacity: false)
                Spacer(minLength: 16)
                Text(verbatim: String(format: "#%02X%02X%02X", Int(selectedColor.red), Int(selectedColor.green), Int(selectedColor.blue)))
                    .font(.system(.callout, design: .monospaced)).foregroundStyle(.secondary)
            }
            .disabled(state == .stopping)

            HStack(spacing: 12) {
                ForEach(ColorPreset.allCases) { preset in
                    Button { selectedColor = preset.color } label: {
                        Circle().fill(preset.color.swiftUIColor)
                            .overlay(Circle().strokeBorder(.primary.opacity(0.25), lineWidth: 1))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(preset.title))
                    .help(Text(preset.title))
                }
            }
            .disabled(state == .stopping)

            VStack(spacing: 6) {
                HStack {
                    Text("lighting.brightness")
                    Spacer()
                    Text(brightness / 100, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit().foregroundStyle(.secondary)
                }
                Slider(value: $brightness, in: 0...100, step: 1) {
                    Text("lighting.brightness")
                }
                .disabled(state == .stopping)
            }

            status

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { buttons }
                VStack(alignment: .leading, spacing: 10) { buttons }
            }
            .disabled(unavailable)
        }
        .onChange(of: selectedColor) { _, _ in updateActiveColor() }
        .onChange(of: brightness) { _, _ in updateActiveColor() }
    }

    @ViewBuilder private var buttons: some View {
        Button("lighting.applyColor", action: applyColor)
            .buttonStyle(.borderedProminent)
        Button {
            colorEnabled = false
            lighting.turnOff(microphone)
        } label: {
            Label("lighting.turnOff", systemImage: "lightbulb.slash")
        }
        if state == .active || state == .sending {
            Button("lighting.stop") { lighting.stop(microphone.id) }
        }
    }

    @ViewBuilder private var status: some View {
        switch state {
        case .sending, .stopping:
            HStack {
                ProgressView().controlSize(.small)
                Text(state == .sending ? LocalizedStringKey("lighting.sending") : LocalizedStringKey("lighting.stopping"))
            }
        case .active:
            let isBlack = lighting.activeColors[microphone.id] == .off
            Label(isBlack ? LocalizedStringKey("lighting.offActive") : LocalizedStringKey("lighting.colorActive"),
                  systemImage: isBlack ? "lightbulb.slash" : "lightbulb.fill")
            Text("lighting.keepOpen").font(.caption).foregroundStyle(.secondary)
        case .failed(let failure):
            Label { Text(failure.message) } icon: { Image(systemName: "exclamationmark.triangle") }
                .font(.callout).foregroundStyle(.orange)
        case .idle:
            Text(microphone.usbIdentity == nil ? LocalizedStringKey("lighting.unavailable") : LocalizedStringKey("lighting.previewHint"))
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var colorSelection: Binding<Color> {
        Binding(get: { selectedColor.swiftUIColor }, set: { color in
            if let rgb = RGBColor(swiftUIColor: color) { selectedColor = rgb }
        })
    }

    private func applyColor() {
        colorEnabled = true
        lighting.apply(microphone, color: selectedColor, brightnessPercent: Int(brightness))
    }

    private func updateActiveColor() {
        guard colorEnabled, state == .active || state == .sending else { return }
        applyColor()
    }

}
