//
//  LightingFailure.swift
//  QuadCastControl
//
//  Created by ByteHasher on 19.10.2026.
//

import Foundation

nonisolated enum LightingFailure: Equatable, Sendable {
    case unavailable, openFailed, unsupported, accessDenied, disconnected, transferFailed
}

extension LightingFailure {
    var message: LocalizedStringResource {
        switch self {
        case .unavailable: "lighting.unavailable"
        case .openFailed: "lighting.openFailed"
        case .unsupported: "lighting.unsupported"
        case .accessDenied: "lighting.accessDenied"
        case .disconnected: "lighting.disconnected"
        case .transferFailed: "lighting.transferFailed"
        }
    }
}
