//
//  WorkspaceNavigation.swift
//  QuadCastControl
//
//  Created by ByteHasher on 19.10.2026.
//

import Foundation

nonisolated enum WorkspaceSection: CaseIterable, Equatable {
    case device, diagnostics, settings
}

nonisolated enum DeviceTab: CaseIterable, Identifiable, Hashable {
    case overview, audio, lighting
    var id: Self { self }
    var title: LocalizedStringResource {
        switch self {
        case .overview: "workspace.overview"
        case .audio: "workspace.audio"
        case .lighting: "workspace.lighting"
        }
    }
}
