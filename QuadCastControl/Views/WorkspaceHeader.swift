//
//  WorkspaceHeader.swift
//  QuadCastControl
//
//  Created by ByteHasher on 19.10.2026.
//

import SwiftUI

struct WorkspaceHeader: View {
    @Environment(\.locale) private var locale
    let microphone: Microphone?
    let section: WorkspaceSection
    @Binding var tab: DeviceTab
    let isScanning: Bool
    let refresh: () -> Void
    let showSettings: () -> Void
    let showDiagnostics: () -> Void
    let draft: LightingDraft
    @State private var showProfile = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Text(verbatim: microphone?.name ?? "QuadCast Control")
                    .font(.system(size: 12, weight: .medium)).lineLimit(1)
                if microphone != nil { Circle().fill(WorkspaceTheme.connected).frame(width: 5, height: 5) }
                Spacer()
                Menu {
                    Button(action: refresh) { Label("discovery.refresh", systemImage: "arrow.clockwise") }
                        .disabled(isScanning)
                    Button("workspace.diagnostics", action: showDiagnostics)
                } label: {
                    Label("workspace.interface", systemImage: "cable.connector")
                        .font(.system(size: 11))
                }
                .menuStyle(.borderlessButton).fixedSize().focusEffectDisabled()
            }
            .foregroundStyle(WorkspaceTheme.muted).padding(.top, 20).padding(.bottom, 16)

            HStack(alignment: .bottom, spacing: 0) {
                if section == .device {
                    HStack(spacing: 27) {
                        ForEach(DeviceTab.allCases) { item in
                            Button { tab = item } label: {
                                Text(item.title.localized(for: locale)).font(.system(size: 23, weight: .light))
                                    .foregroundStyle(tab == item ? WorkspaceTheme.text : WorkspaceTheme.muted)
                                    .padding(.bottom, 16)
                                    .overlay(alignment: .bottom) {
                                        if tab == item { WorkspaceTheme.accent.frame(height: 2) }
                                    }
                            }.buttonStyle(.plain).focusEffectDisabled()
                        }
                    }
                } else {
                    Text(section == .settings ? LocalizedStringKey("workspace.settings") : LocalizedStringKey("workspace.diagnostics"))
                        .font(.system(size: 23, weight: .light)).padding(.bottom, 16)
                }
                Spacer()
                headerButton("workspace.settings", icon: "gearshape", action: showSettings)
                headerButton("workspace.profile", icon: "slider.horizontal.3") { showProfile.toggle() }
                    .popover(isPresented: $showProfile, arrowEdge: .bottom) {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("workspace.profile").font(.headline)
                            HStack {
                                Circle().fill(draft.color.swiftUIColor).frame(width: 22, height: 22)
                                Text(verbatim: String(format: "#%02X%02X%02X", Int(draft.color.red), Int(draft.color.green), Int(draft.color.blue)))
                                    .monospaced()
                                Spacer()
                                Text(Double(draft.brightnessPercent) / 100, format: .percent)
                            }
                            Text("workspace.profileLocal").font(.callout).foregroundStyle(.secondary)
                        }.padding(22).frame(width: 285)
                    }
            }
        }
        .padding(.horizontal, 28).background(WorkspaceTheme.header)
        .overlay(alignment: .bottom) { WorkspaceTheme.line.frame(height: 1) }
    }

    private func headerButton(_ title: LocalizedStringResource, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 20, weight: .light))
                Text(title.localized(for: locale)).font(.system(size: 9))
            }.frame(width: 70).padding(.bottom, 15).foregroundStyle(WorkspaceTheme.muted)
        }.buttonStyle(.plain).focusEffectDisabled()
    }
}
