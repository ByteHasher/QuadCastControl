//
//  WorkspaceDetailsView.swift
//  QuadCastControl
//
//  Created by ByteHasher on 19.10.2026.
//

import AppKit
import SwiftUI

struct WorkspaceDetailsView: View {
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.system
    let section: WorkspaceSection
    let tab: DeviceTab
    let microphone: Microphone?
    let draft: LightingDraft
    let hidState: HIDDiscoveryState

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if section == .device && tab == .overview {
                        MicrophoneStage(microphone: microphone, draft: draft,
                                        height: max(240, geometry.size.height * 0.58))
                        overview.padding(.horizontal, 28)
                    } else if section == .device {
                        audio.padding(28)
                    } else if section == .diagnostics {
                        diagnostics.padding(28)
                    } else {
                        settings.padding(28)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 28)
            }
        }
    }

    private var overview: some View {
        HStack(alignment: .top, spacing: 20) {
            WorkspaceCard(title: "workspace.connection") {
                LabeledContent("workspace.microphone") { Text(verbatim: microphone?.name ?? "—") }
                LabeledContent("workspace.connection") {
                    Text(microphone == nil ? LocalizedStringKey("discovery.disconnected") : LocalizedStringKey("discovery.connectedUSB"))
                }
                LabeledContent("workspace.hidInterfaces") { Text(microphone?.hidInterfaces.count ?? 0, format: .number) }
            }
            WorkspaceCard(title: "workspace.lighting") {
                Label("workspace.liveControl", systemImage: "lightbulb")
                Text("workspace.previewFooter").font(.callout).foregroundStyle(WorkspaceTheme.muted)
            }
        }
    }

    private var audio: some View {
        WorkspaceCard(title: "workspace.audio") {
            Label(microphone == nil ? LocalizedStringKey("discovery.disconnected") : LocalizedStringKey("discovery.connectedUSB"), systemImage: "mic")
            if let microphone { Text(verbatim: microphone.name).font(.title3) }
            Text("workspace.audioDescription").foregroundStyle(WorkspaceTheme.muted).lineSpacing(5)
            Button("workspace.openSystemSettings") {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
            }.buttonStyle(.bordered)
        }
    }

    private var diagnostics: some View {
        VStack(alignment: .leading, spacing: 20) {
            WorkspaceCard(title: "workspace.connection") {
                LabeledContent("workspace.microphone") { Text(verbatim: microphone?.name ?? "—") }
                if let identity = microphone?.usbIdentity {
                    LabeledContent("workspace.usbIdentity") { Text(verbatim: String(identity.deviceRegistryID)).monospaced() }
                }
                LabeledContent("workspace.hidInterfaces") { Text(microphone?.hidInterfaces.count ?? 0, format: .number) }
                if case .failed(let status) = hidState {
                    Text(verbatim: String(format: "IOHIDManager: 0x%08X", UInt32(bitPattern: status)))
                        .font(.callout.monospaced()).foregroundStyle(WorkspaceTheme.warning)
                }
            }
            ForEach(microphone?.hidInterfaces ?? []) { interface in
                WorkspaceCard(title: "workspace.interface") {
                    Text(verbatim: String(format: "VID %04X  ·  PID %04X", interface.vendorID, interface.productID))
                        .font(.callout.monospaced())
                    Text(verbatim: String(format: "Usage %04X:%04X", interface.usagePage, interface.usage))
                        .font(.callout.monospaced()).foregroundStyle(WorkspaceTheme.muted)
                    Text(verbatim: "Input: \(interface.capabilities.inputReportSize)  ·  Output: \(interface.capabilities.outputReportSize)  ·  Feature: \(interface.capabilities.featureReportSize)")
                        .font(.callout.monospaced()).foregroundStyle(WorkspaceTheme.muted)
                }
            }
        }.textSelection(.enabled)
    }

    private var settings: some View {
        WorkspaceCard(title: "workspace.settings") {
            LabeledContent("workspace.language") { Text("workspace.systemLanguage") }
            Picker("workspace.appearance", selection: $appearance) {
                ForEach(AppAppearance.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.menu)
            Divider()
            Text("workspace.profileLocal").foregroundStyle(WorkspaceTheme.muted).lineSpacing(5)
            Text("workspace.unofficial").font(.callout).foregroundStyle(WorkspaceTheme.muted)
        }
    }
}

private struct WorkspaceCard<Content: View>: View {
    let title: LocalizedStringResource
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ConsoleHeading(title: title).padding(.bottom, 5)
            content
        }
        .padding(24).frame(maxWidth: .infinity, alignment: .leading)
        .background(WorkspaceTheme.panel, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(WorkspaceTheme.line))
    }
}
