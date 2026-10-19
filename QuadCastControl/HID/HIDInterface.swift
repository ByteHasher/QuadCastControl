//
//  HIDInterface.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

import Foundation

nonisolated struct USBProductID: Hashable, Sendable {
    let vendor: Int
    let product: Int
}

nonisolated enum QuadCastSDeviceIDs {
    // USB identifiers are hardware facts, not permission to send vendor commands.
    static let controllers: Set<USBProductID> = [
        .init(vendor: 0x0951, product: 0x171f),
        .init(vendor: 0x03f0, product: 0x0f8b),
        .init(vendor: 0x03f0, product: 0x028c),
        .init(vendor: 0x03f0, product: 0x048c),
        .init(vendor: 0x03f0, product: 0x068c)
    ]

    static func contains(vendor: Int, product: Int) -> Bool {
        controllers.contains(.init(vendor: vendor, product: product))
    }
}

nonisolated struct HIDCapabilities: Equatable, Sendable {
    let inputReportSize: Int
    let outputReportSize: Int
    let featureReportSize: Int

    static let mock = Self(inputReportSize: 64, outputReportSize: 64, featureReportSize: 64)
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

nonisolated enum MicrophoneHIDBinder {
    /// Audio devices own the list. A HID-only endpoint never creates another microphone row.
    static func bind(_ microphones: [Microphone], interfaces: [HIDInterface]) -> [Microphone] {
        var result = microphones.map { microphone in
            var copy = microphone
            copy.hidInterfaces = []
            return copy
        }
        for interface in interfaces {
            guard QuadCastSDeviceIDs.contains(vendor: interface.vendorID, product: interface.productID),
                  let hidUSB = interface.usbIdentity else { continue }
            let matches = result.indices.filter { index in
                guard result[index].model == .quadCastS,
                      let audioUSB = result[index].usbIdentity else { return false }
                return audioUSB.deviceRegistryID == hidUSB.deviceRegistryID
                    || (audioUSB.enclosureRegistryID != nil
                        && audioUSB.enclosureRegistryID == hidUSB.enclosureRegistryID)
            }
            // Never pick the first same-name device when identity is missing or ambiguous.
            guard matches.count == 1 else { continue }
            let index = matches[0]
            if !result[index].hidInterfaces.contains(where: { $0.id == interface.id }) {
                result[index].hidInterfaces.append(interface)
            }
        }
        for index in result.indices { result[index].hidInterfaces.sort { $0.id < $1.id } }
        return result
    }
}
