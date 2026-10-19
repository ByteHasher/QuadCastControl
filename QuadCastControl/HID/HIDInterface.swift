//
//  HIDInterface.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

import Foundation

nonisolated struct HIDCapabilities: Equatable, Sendable {
    let inputReportSize: Int
    let outputReportSize: Int
    let featureReportSize: Int
}

nonisolated struct HIDInterface: Identifiable, Equatable, Sendable {
    let id: UInt64
    let vendorID: Int
    let productID: Int
    let usagePage: Int
    let usage: Int
    let capabilities: HIDCapabilities
    let usbIdentity: USBDeviceIdentity?
}

nonisolated enum HIDDiscoveryState: Equatable, Sendable {
    case stopped
    case running
    case failed(Int32)
}
