//
//  QuadCastControlApp.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

import SwiftUI

@main
struct QuadCastControlApp: App {
    var body: some Scene {
        WindowGroup {
            AppAppearanceView {
                ContentView()
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1240, height: 820)
        .windowResizability(.contentMinSize)
    }
}
