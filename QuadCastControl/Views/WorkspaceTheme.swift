//
//  WorkspaceTheme.swift
//  QuadCastControl
//
//  Created by ByteHasher on 19.10.2026.
//

import SwiftUI

enum WorkspaceTheme {
    // Asset variants resolve from SwiftUI's colorScheme, including an explicit
    // in-app override, rather than AppKit's current drawing appearance.
    static let background = Color("WorkspaceBackground")
    static let panel = Color("WorkspacePanel")
    static let header = Color("WorkspaceHeader")
    static let sidebarTop = Color("WorkspaceSidebarTop")
    static let sidebarBottom = Color("WorkspaceSidebarBottom")
    static let text = Color("WorkspaceText")
    static let line = Color("WorkspaceLine")
    static let muted = Color("WorkspaceMuted")
    static let accent = Color("WorkspaceAccent")
    static let sidebarSelection = accent.opacity(0.12)
    static let connected = Color("WorkspaceConnected")
    static let live = Color("WorkspaceLive")
    static let warning = Color("WorkspaceWarning")
    static let selectionRing = Color("WorkspaceSelectionRing")
}

struct ConsoleHeading: View {
    @Environment(\.locale) private var locale
    let title: LocalizedStringResource
    var body: some View {
        Text(title.localized(for: locale)).textCase(.uppercase).font(.system(size: 11, weight: .semibold))
            .tracking(1.5).foregroundStyle(WorkspaceTheme.muted)
    }
}
