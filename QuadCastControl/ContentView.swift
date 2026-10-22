import SwiftUI

struct ContentView: View {
    @Environment(MicrophoneDiscovery.self) private var discovery
    @Environment(LightingControl.self) private var lighting
    @State private var selectedID: String?
    @State private var section = WorkspaceSection.device
    @State private var tab = DeviceTab.lighting
    @State private var collapsed = false
    @State private var drafts: [String: LightingDraft] = [:]

    private var microphone: Microphone? {
        discovery.microphones.first { $0.id == selectedID } ?? discovery.microphones.first
    }

    private var draft: Binding<LightingDraft> {
        let key = microphone?.id ?? "disconnected-preview"
        return Binding(get: { drafts[key] ?? LightingDraft() }, set: { drafts[key] = $0 })
    }

    var body: some View {
        HStack(spacing: 0) {
            WorkspaceSidebar(microphones: discovery.microphones, selectedID: $selectedID,
                             section: $section, collapsed: $collapsed)
            VStack(spacing: 0) {
                WorkspaceHeader(microphone: microphone, section: section, tab: $tab,
                                isScanning: discovery.isScanning, refresh: discovery.refresh,
                                showSettings: { section = .settings }, showDiagnostics: { section = .diagnostics },
                                draft: draft.wrappedValue)
                if discovery.scanFailed {
                    Label("discovery.errorDetail", systemImage: "exclamationmark.triangle")
                        .font(.callout).foregroundStyle(WorkspaceTheme.warning).padding(14).frame(maxWidth: .infinity, alignment: .leading)
                }
                if section == .device && tab == .lighting {
                    MicrophoneLightingView(microphone: microphone, lighting: lighting, draft: draft)
                        .id(microphone?.id)
                } else {
                    WorkspaceDetailsView(section: section, tab: tab, microphone: microphone,
                                         draft: draft.wrappedValue, hidState: discovery.hidState)
                }
                if !discovery.automaticUpdatesAvailable {
                    Text("discovery.manualRefreshHint").font(.caption).foregroundStyle(WorkspaceTheme.muted).padding(10)
                }
            }
        }
        .frame(minWidth: 1024, idealWidth: 1240, minHeight: 680, idealHeight: 820)
        .background(WorkspaceTheme.background)
        .foregroundStyle(WorkspaceTheme.text).tint(WorkspaceTheme.accent)
        .task { discovery.start() }
        .onChange(of: discovery.microphones) { _, microphones in
            lighting.reconcile(microphones)
            if !microphones.contains(where: { $0.id == selectedID }) { selectedID = microphones.first?.id }
        }
        .onDisappear { lighting.stopAll(); discovery.stop() }
    }
}

#Preview {
    ContentView()
        .environment(MicrophoneDiscovery())
        .environment(LightingControl())
}
