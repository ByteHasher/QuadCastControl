//
//  MicrophoneLightingView.swift
//  QuadCastControl
//
//  Created by ByteHasher on 19.10.2026.
//

import SwiftUI

struct MicrophoneLightingView: View {
    @Environment(\.locale) private var locale
    let microphone: Microphone?
    @Bindable var lighting: LightingControl
    @Binding var draft: LightingDraft

    private var state: LightingState { microphone.flatMap { lighting.states[$0.id] } ?? .idle }
    private var available: Bool { microphone?.model == .quadCastS && microphone?.usbIdentity != nil && state != .stopping }
    private var controlling: Bool { state == .active || state == .sending }
    // The button represents the selected lighting state, not the USB session.
    // Transfer progress and success are shown separately by controlStatus.
    private var powerIsOn: Bool { draft.enabled }
    private let consoleHeight: CGFloat = 320

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // The flexible stage receives only the height left after the
                // controls and the footer have taken their full required space.
                MicrophoneStage(microphone: microphone, draft: draft)
                    .frame(minHeight: 0, maxHeight: .infinity)
                if microphone?.model != .quadCastS && microphone != nil {
                    Text("workspace.lightingUnsupported")
                        .font(.callout).foregroundStyle(WorkspaceTheme.muted).padding(20)
                        .fixedSize(horizontal: false, vertical: true).layoutPriority(1)
                }
                HStack(alignment: .top, spacing: 0) {
                    effectColumn.frame(width: geometry.size.width * 0.20)
                    brightnessColumn.frame(width: geometry.size.width * 0.19)
                    colorColumn.frame(width: geometry.size.width * 0.35)
                    controlColumn.frame(width: geometry.size.width * 0.26)
                }
                .frame(height: consoleHeight).background(WorkspaceTheme.panel).layoutPriority(1)
                footer.fixedSize(horizontal: false, vertical: true).layoutPriority(1)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private var effectColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            ConsoleHeading(title: "workspace.effect").padding(20)
            HStack(spacing: 12) {
                Image(systemName: "circle.lefthalf.filled").font(.system(size: 23, weight: .ultraLight))
                VStack(alignment: .leading, spacing: 6) {
                    Text("workspace.solid").font(.system(size: 12, weight: .semibold))
                    Text("workspace.bothZones").font(.system(size: 10)).foregroundStyle(.white.opacity(0.6))
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20).padding(.vertical, 15)
            .background(LinearGradient(colors: [Color(red: 0.04, green: 0.21, blue: 0.56),
                                               Color(red: 0.05, green: 0.30, blue: 0.68)],
                                       startPoint: .leading, endPoint: .trailing))
            .overlay(alignment: .leading) { WorkspaceTheme.accent.frame(width: 3) }
            Text("workspace.solidDescription").font(.system(size: 11)).lineSpacing(6)
                .foregroundStyle(WorkspaceTheme.muted).padding(20)
            Spacer(minLength: 0)
        }
        .frame(height: consoleHeight, alignment: .top).columnDivider()
    }

    private var brightnessColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            ConsoleHeading(title: "lighting.brightness").padding(.bottom, 26)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(draft.brightnessPercent, format: .number).font(.system(size: 42, weight: .ultraLight)).monospacedDigit()
                Text(verbatim: "%").font(.system(size: 14)).foregroundStyle(WorkspaceTheme.muted)
                Spacer(minLength: 0)
                Image(systemName: "sun.max").font(.system(size: 20, weight: .ultraLight)).foregroundStyle(WorkspaceTheme.muted)
            }
            Slider(value: Binding(get: { Double(draft.brightnessPercent) }, set: {
                draft.brightnessPercent = Int($0.rounded())
                applyLiveColor()
            }), in: 0...100)
            .controlSize(.small).padding(.top, 16).disabled(!available).accessibilityLabel("lighting.brightness")
            HStack {
                Text("workspace.darker")
                Spacer()
                Text("workspace.brighter")
            }.font(.system(size: 10)).foregroundStyle(WorkspaceTheme.muted).padding(.top, 4)
            Spacer(minLength: 0)
        }
        .padding(20).frame(height: consoleHeight, alignment: .top).columnDivider()
    }

    private var powerActionTitle: LocalizedStringResource {
        powerIsOn ? "lighting.turnOff" : "lighting.turnOn"
    }

    private var lightingPowerButton: some View {
        Button {
            guard available, let microphone else { return }
            draft.enabled.toggle()
            if draft.enabled { applyLiveColor() } else { lighting.turnOff(microphone) }
        } label: {
            Image(systemName: "power")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(powerIsOn ? WorkspaceTheme.accent : WorkspaceTheme.muted)
                .frame(width: 40, height: 40)
                .background(Circle().fill(powerIsOn ? WorkspaceTheme.accent.opacity(0.14) : WorkspaceTheme.background))
                .overlay(Circle().stroke(powerIsOn ? WorkspaceTheme.accent.opacity(0.45) : WorkspaceTheme.line, lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.plain).focusEffectDisabled().disabled(!available)
        .opacity(available ? 1 : 0.35)
        .help(Text(powerActionTitle.localized(for: locale)))
        .accessibilityLabel(Text(powerActionTitle.localized(for: locale)))
        .accessibilityValue(Text(powerIsOn ? LocalizedStringKey("workspace.lightsOn") : LocalizedStringKey("workspace.lightsOff")))
    }

    private var colorColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ConsoleHeading(title: "lighting.color")
                Spacer()
                ColorPicker("lighting.color", selection: colorSelection, supportsOpacity: false)
                    .labelsHidden().controlSize(.mini).frame(width: 25)
            }
            HStack(alignment: .top, spacing: 18) {
                HueWheel(color: liveColorSelection).frame(maxWidth: 158).frame(height: 185)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(21), spacing: 9), count: 3), spacing: 12) {
                    ForEach(ColorPreset.allCases) { preset in
                        Button { liveColorSelection.wrappedValue = preset.color } label: {
                            Circle().fill(preset.color.swiftUIColor).frame(width: 21, height: 21)
                                .overlay(Circle().stroke(draft.color == preset.color ? WorkspaceTheme.selectionRing : WorkspaceTheme.line,
                                                        lineWidth: draft.color == preset.color ? 2 : 0.6))
                        }.buttonStyle(.plain).focusEffectDisabled()
                            .accessibilityLabel(Text(preset.title.localized(for: locale)))
                            .help(Text(preset.title.localized(for: locale)))
                    }
                }.frame(width: 81).padding(.top, 4)
            }
            HStack {
                Text(verbatim: String(format: "#%02X%02X%02X", Int(draft.color.red), Int(draft.color.green), Int(draft.color.blue)))
                    .font(.system(size: 12, weight: .medium, design: .monospaced)).textSelection(.enabled)
                Spacer()
                Text(verbatim: "RGB").font(.system(size: 10)).foregroundStyle(WorkspaceTheme.muted)
            }
            .padding(.horizontal, 12).frame(height: 35)
            .background(WorkspaceTheme.background, in: RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(WorkspaceTheme.line))
            Spacer(minLength: 0)
        }
        .padding(20).frame(height: consoleHeight, alignment: .top).columnDivider()
        .disabled(!available)
    }

    private var controlColumn: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                ConsoleHeading(title: "workspace.control")
                Spacer(minLength: 8)
                lightingPowerButton
            }
            .padding(.bottom, 10)
            controlStatus
            if controlling {
                Button { if let microphone { lighting.stop(microphone.id) } } label: {
                    Label("workspace.stop", systemImage: "stop.fill").font(.system(size: 11))
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(WorkspaceTheme.background, in: RoundedRectangle(cornerRadius: 5))
                }.buttonStyle(.plain).focusEffectDisabled()
            }
            Text("workspace.liveHint").font(.system(size: 11))
                .foregroundStyle(WorkspaceTheme.muted).lineLimit(1).minimumScaleFactor(0.8)
            Spacer(minLength: 0)
        }.padding(20).frame(height: consoleHeight, alignment: .top)
    }

    @ViewBuilder private var controlStatus: some View {
        switch state {
        case .sending, .stopping:
            HStack(spacing: 8) {
                ProgressView().controlSize(.mini)
                Text(state == .sending ? LocalizedStringKey("lighting.sending") : LocalizedStringKey("lighting.stopping"))
                    .font(.system(size: 11))
            }
        case .active:
            let requestedColor = draft.enabled ? draft.color.scaled(byPercent: draft.brightnessPercent) : .off
            if let microphone, lighting.activeColors[microphone.id] == requestedColor {
                HStack(spacing: 8) {
                    Circle().fill(draft.enabled ? WorkspaceTheme.live : WorkspaceTheme.muted).frame(width: 6, height: 6)
                    Text(draft.enabled ? LocalizedStringKey("workspace.liveOnMicrophone") : LocalizedStringKey("workspace.off"))
                        .font(.system(size: 12))
                }
                .foregroundStyle(draft.enabled ? WorkspaceTheme.live : WorkspaceTheme.muted)
                .accessibilityElement(children: .combine)
            } else {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.mini)
                    Text("lighting.sending").font(.system(size: 11))
                }
            }
        case .failed(let failure):
            Label { Text(failure.message.localized(for: locale)) } icon: { Image(systemName: "exclamationmark.triangle") }
                .font(.system(size: 10)).foregroundStyle(WorkspaceTheme.warning).fixedSize(horizontal: false, vertical: true)
        case .idle:
            Label(microphone == nil ? LocalizedStringKey("discovery.disconnected") : LocalizedStringKey("workspace.notApplied"),
                  systemImage: "circle.dashed")
                .font(.system(size: 11)).foregroundStyle(WorkspaceTheme.muted)
        }
    }

    private var footer: some View {
        Label("workspace.previewFooter", systemImage: "info.circle")
            .font(.system(size: 10)).foregroundStyle(WorkspaceTheme.muted)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 24).padding(.vertical, 14)
            .background(WorkspaceTheme.background)
            .overlay(alignment: .top) { WorkspaceTheme.line.frame(height: 1) }
    }

    private var colorSelection: Binding<Color> {
        Binding(get: { draft.color.swiftUIColor }, set: {
            if let rgb = RGBColor(swiftUIColor: $0) { liveColorSelection.wrappedValue = rgb }
        })
    }

    private var liveColorSelection: Binding<RGBColor> {
        Binding(get: { draft.color }, set: {
            draft.color = $0
            applyLiveColor()
        })
    }

    private func applyLiveColor() {
        guard let microphone, available, draft.enabled else { return }
        lighting.apply(microphone, color: draft.color, brightnessPercent: draft.brightnessPercent)
    }
}

private extension View {
    func columnDivider() -> some View {
        overlay(alignment: .trailing) { WorkspaceTheme.line.frame(width: 1) }
    }
}
