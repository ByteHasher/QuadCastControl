//
//  USBDeviceIdentity.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

import Foundation

nonisolated struct USBDeviceIdentity: Equatable, Sendable {
    let deviceRegistryID: UInt64
    let locationID: UInt32?
    /// Only populated for a verified internal QuadCast S hub, never an arbitrary shared USB hub.
    let enclosureRegistryID: UInt64?
}

nonisolated struct USBRegistryDevice: Equatable, Sendable {
    let registryID: UInt64
    let parentRegistryID: UInt64?
    let vendorID: Int
    let productID: Int
    let manufacturer: String
    let productName: String
    let serialNumber: String?
    let locationID: UInt32?
}

nonisolated enum USBIdentityResolver {
    /// Apple's documented USB Audio UID layout: TN3190, Device Naming.
    /// No substring or product-name-only fallback is permitted.
    static func audioIdentity(uid: String, devices: [USBRegistryDevice]) -> USBDeviceIdentity? {
        let matches = devices.filter { device in
            let prefix = "AppleUSBAudioEngine:\(device.manufacturer):\(device.productName):"
            guard uid.hasPrefix(prefix) else { return false }
            let components = uid.dropFirst(prefix.count).split(separator: ":", omittingEmptySubsequences: false)
            guard components.count == 2,
                  !components[1].isEmpty,
                  components[1].split(separator: ",", omittingEmptySubsequences: false)
                    .allSatisfy({ UInt32($0) != nil }) else { return false }
            let identifier = String(components[0])
            if let serial = device.serialNumber, !serial.isEmpty { return identifier == serial }
            guard let location = device.locationID, location != 0 else { return false }
            return identifier.lowercased() == String(location, radix: 16)
        }
        guard matches.count == 1 else { return nil }
        return identity(for: matches[0].registryID, devices: devices)
    }

    static func identity(for registryID: UInt64, devices: [USBRegistryDevice]) -> USBDeviceIdentity? {
        guard let device = devices.first(where: { $0.registryID == registryID }) else { return nil }
        var enclosure: UInt64?
        if let parentID = device.parentRegistryID,
           let parent = devices.first(where: { $0.registryID == parentID }),
           parent.vendorID == 0x214b, parent.productID == 0x7250 {
            // Observed read-only on the HP 028C/0294 revision: both USB functions live
            // behind this internal hub. Do not extend this rule to unverified hubs/revisions.
            let children = devices.filter { $0.parentRegistryID == parentID }
            let controller = USBProductID(vendor: 0x03f0, product: 0x028c)
            let audio = USBProductID(vendor: 0x03f0, product: 0x0294)
            let childIDs = children.map { USBProductID(vendor: $0.vendorID, product: $0.productID) }
            if children.count == 2, Set(childIDs) == Set([controller, audio]),
               [controller, audio].contains(.init(vendor: device.vendorID, product: device.productID)) {
                enclosure = parentID
            }
        }
        return .init(deviceRegistryID: device.registryID, locationID: device.locationID,
                     enclosureRegistryID: enclosure)
    }
}
