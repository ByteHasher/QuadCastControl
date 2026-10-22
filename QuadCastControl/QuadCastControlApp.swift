//
//  QuadCastControlApp.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

import SwiftUI

@main
struct QuadCastControlApp: App {
    // One discovery and lighting controller per process: a microphone must never
    // receive two concurrent color streams.
    @State private var discovery = MicrophoneDiscovery()
    @State private var lighting = LightingControl()

    var body: some Scene {
        // A single-instance window: WindowGroup would let File › New Window open a
        // second workspace with its own drafts driving the same shared controller.
        Window("discovery.appTitle", id: "workspace") {
            AppAppearanceView {
                ContentView()
            }
            .environment(discovery)
            .environment(lighting)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1240, height: 820)
        .windowResizability(.contentMinSize)
    }
}
