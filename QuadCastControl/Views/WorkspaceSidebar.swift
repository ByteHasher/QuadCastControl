//
//  WorkspaceSidebar.swift
//  QuadCastControl
//
//  Created by ByteHasher on 19.10.2026.
//

import SwiftUI

struct WorkspaceSidebar: View {
    let microphones: [Microphone]
    @Binding var selectedID: String?
    @Binding var section: WorkspaceSection
    @Binding var collapsed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "waveform").font(.system(size: 27, weight: .light))
                    .foregroundStyle(WorkspaceTheme.accent)
                if !collapsed {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(verbatim: "QUADCAST").font(.system(size: 17, weight: .bold)).tracking(2.7)
                        Text(verbatim: "CONTROL").font(.system(size: 11, weight: .semibold)).tracking(4.4).opacity(0.65)
                    }
                }
            }
            .foregroundStyle(.white.opacity(0.9))
            .frame(maxWidth: .infinity, alignment: collapsed ? .center : .leading)
            .padding(.horizontal, collapsed ? 0 : 25).padding(.top, 34).padding(.bottom, 46)

            if !collapsed {
                ConsoleHeading(title: "workspace.devices").foregroundStyle(.white.opacity(0.65))
                    .padding(.horizontal, 24).padding(.bottom, 18)
            }
            if microphones.isEmpty {
                sidebarButton("discovery.disconnected", icon: "mic", selected: section == .device) { section = .device }
            } else {
                ForEach(microphones) { microphone in
                    let selected = section == .device && (selectedID == microphone.id || (selectedID == nil && microphone.id == microphones.first?.id))
                    Button {
                        selectedID = microphone.id
                        section = .device
                    } label: {
                        HStack(spacing: 15) {
                            Image(systemName: "mic").font(.system(size: 18, weight: .light)).frame(width: 22)
                                .foregroundStyle(selected ? WorkspaceTheme.accent : WorkspaceTheme.muted)
                            if !collapsed {
                                VStack(alignment: .leading, spacing: 7) {
                                    Text(verbatim: microphone.model.rawValue)
                                        .font(.system(size: 13, weight: .semibold)).lineLimit(1)
                                    HStack(spacing: 6) {
                                        Circle().fill(WorkspaceTheme.connected).frame(width: 5, height: 5)
                                        Text("discovery.connectedUSB").font(.system(size: 10))
                                    }.foregroundStyle(.white.opacity(0.65))
                                }
                                Spacer(minLength: 0)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: collapsed ? .center : .leading)
                        .padding(.horizontal, collapsed ? 0 : 24).frame(height: collapsed ? 52 : 68)
                        .foregroundStyle(.white.opacity(selected ? 0.95 : 0.8))
                        .background(selected ? WorkspaceTheme.sidebarSelection : .clear)
                        .overlay(alignment: .leading) { if selected { WorkspaceTheme.accent.frame(width: 3) } }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain).focusEffectDisabled().help(microphone.name)
                    .accessibilityLabel(Text(verbatim: microphone.name))
                }
            }
            Rectangle().fill(WorkspaceTheme.line).frame(height: 1)
                .padding(.horizontal, collapsed ? 14 : 24).padding(.vertical, 18)
            sidebarButton("workspace.diagnostics", icon: "waveform.path.ecg", selected: section == .diagnostics) { section = .diagnostics }
            Spacer()
            sidebarButton("workspace.settings", icon: "gearshape", selected: section == .settings) { section = .settings }
            if !collapsed {
                Text("workspace.unofficial").font(.system(size: 10)).lineSpacing(5)
                    .foregroundStyle(.white.opacity(0.4)).padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 25)
            }
        }
        .frame(width: collapsed ? 68 : 224)
        .frame(maxHeight: .infinity)
        .background(LinearGradient(colors: [WorkspaceTheme.sidebarTop, WorkspaceTheme.sidebarBottom],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
        .overlay(alignment: .trailing) { WorkspaceTheme.line.frame(width: 1) }
        .overlay(alignment: collapsed ? .top : .topTrailing) {
            Button { withAnimation(.easeInOut(duration: 0.18)) { collapsed.toggle() } } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 14))
                    .foregroundStyle(WorkspaceTheme.muted)
                    .frame(width: 32, height: 32).contentShape(Rectangle())
            }
            .buttonStyle(.plain).focusEffectDisabled()
            .help("workspace.toggleSidebar").accessibilityLabel("workspace.toggleSidebar")
            .padding(.top, 2).padding(.trailing, collapsed ? 0 : 10)
        }
    }

    private func sidebarButton(_ title: LocalizedStringResource, icon: String, selected: Bool,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon).font(.system(size: 18, weight: .light)).frame(width: 22)
                    .foregroundStyle(selected ? WorkspaceTheme.accent : WorkspaceTheme.muted)
                if !collapsed {
                    Text(title).font(.system(size: 13, weight: selected ? .semibold : .medium))
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: collapsed ? .center : .leading)
            .padding(.horizontal, collapsed ? 0 : 24).frame(height: 52)
            .foregroundStyle(.white.opacity(selected ? 0.95 : 0.8))
            .background(selected ? WorkspaceTheme.sidebarSelection : .clear)
            .overlay(alignment: .leading) { if selected { WorkspaceTheme.accent.frame(width: 3) } }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain).focusEffectDisabled().help(Text(title))
        .accessibilityLabel(Text(title))
    }
}
