//
//  MicrophoneHIDBinder.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

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
