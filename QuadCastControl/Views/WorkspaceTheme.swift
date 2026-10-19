//
//  WorkspaceTheme.swift
//  QuadCastControl
//
//  Created by ByteHasher on 19.10.2026.
//

import SwiftUI

enum WorkspaceTheme {
    static let background = Color(red: 0.105, green: 0.113, blue: 0.121)
    static let panel = Color(red: 0.13, green: 0.14, blue: 0.15)
    static let header = Color(red: 0.12, green: 0.13, blue: 0.14)
    static let sidebarTop = Color(red: 0.125, green: 0.137, blue: 0.153)
    static let sidebarBottom = Color(red: 0.09, green: 0.102, blue: 0.114)
    static let line = Color.white.opacity(0.10)
    static let muted = Color(red: 0.58, green: 0.61, blue: 0.66)
    static let accent = Color(red: 0, green: 0.65, blue: 0.96)
    static let sidebarSelection = accent.opacity(0.12)
    static let connected = Color(red: 0.05, green: 0.80, blue: 0.70)
}

struct ConsoleHeading: View {
    let title: LocalizedStringResource
    var body: some View {
        Text(title).textCase(.uppercase).font(.system(size: 11, weight: .semibold))
            .tracking(1.5).foregroundStyle(WorkspaceTheme.muted)
    }
}
