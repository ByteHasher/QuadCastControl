//
//  ContentView.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var discovery = MicrophoneDiscovery()
    @State private var lighting = LightingControl()

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("discovery.appTitle")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button(action: discovery.refresh) {
                    Label("discovery.refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(discovery.isScanning)
            }

            if discovery.scanFailed {
                connectionMessage(title: "discovery.errorTitle", detail: "discovery.errorDetail",
                                  symbol: "exclamationmark.triangle", color: .orange)
            } else if discovery.isScanning && discovery.microphones.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("discovery.scanning").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if discovery.microphones.isEmpty {
                connectionMessage(title: "discovery.disconnected", detail: "discovery.connectHint",
                                  symbol: "mic.slash", color: .secondary)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(discovery.microphones) { microphone in
                            microphoneRow(microphone)
                        }
                    }
                }
            }

            if !discovery.automaticUpdatesAvailable {
                Label("discovery.manualRefreshHint", systemImage: "info.circle")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding(28)
        .frame(minWidth: 480, idealWidth: 560, minHeight: 340, idealHeight: 560)
        .task { discovery.start() }
        .onChange(of: discovery.microphones) { _, microphones in lighting.reconcile(microphones) }
        .onDisappear { lighting.stopAll(); discovery.stop() }
    }

    private func microphoneRow(_ microphone: Microphone) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            microphoneDetails(microphone)
            if microphone.model == .quadCastS {
                Divider()
                MicrophoneLightingView(microphone: microphone, lighting: lighting)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }

    private func microphoneDetails(_ microphone: Microphone) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "mic.fill")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.tint)
                .frame(width: 44)
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: microphone.name).font(.headline).textSelection(.enabled)
                Label("discovery.connectedUSB", systemImage: "circle.fill")
                    .labelStyle(StatusLabelStyle(color: .green))
                    .font(.callout).foregroundStyle(.secondary)
                if microphone.model == .quadCastS {
                    hidStatus(for: microphone)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "cable.connector").foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func hidStatus(for microphone: Microphone) -> some View {
        if !microphone.hidInterfaces.isEmpty {
            Label("hid.connected", systemImage: "link")
                .font(.caption).foregroundStyle(.secondary)
        } else if case .failed = discovery.hidState {
            Label("hid.accessUnavailable", systemImage: "exclamationmark.triangle")
                .font(.caption).foregroundStyle(.orange)
        } else {
            Label("hid.notLinked", systemImage: "link.badge.plus")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func connectionMessage(title: LocalizedStringKey, detail: LocalizedStringKey,
                                   symbol: String, color: Color) -> some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 48, weight: .light)).foregroundStyle(color)
            Text(title).font(.headline)
            Text(detail).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct StatusLabelStyle: LabelStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon
                .font(.system(size: 8))
                .foregroundStyle(color)
            configuration.title
        }
    }
}

#Preview {
    ContentView()
}
