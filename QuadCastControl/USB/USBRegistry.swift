//
//  USBRegistry.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

import Foundation
import IOKit

/// Passive IORegistry metadata only: no USB device/interface open and no control transfers.
nonisolated enum USBRegistry {
    static func devices() -> [USBRegistryDevice] {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOUSBHostDevice"),
                                          &iterator) == KERN_SUCCESS else { return [] }
        defer { IOObjectRelease(iterator) }
        var result: [USBRegistryDevice] = []
        while true {
            let service = IOIteratorNext(iterator)
            guard service != 0 else { break }
            defer { IOObjectRelease(service) }
            guard let registryID = registryID(service),
                  let vendor = number(service, "idVendor"),
                  let product = number(service, "idProduct") else { continue }
            result.append(.init(registryID: registryID, parentRegistryID: parentUSBRegistryID(service),
                vendorID: vendor.intValue, productID: product.intValue,
                manufacturer: string(service, "USB Vendor Name") ?? "Unknown Manufacturer",
                productName: string(service, "USB Product Name") ?? "Unknown USB Audio Device",
                serialNumber: string(service, "USB Serial Number"),
                locationID: number(service, "locationID")?.uint32Value))
        }
        return result
    }

    static func deviceRegistryID(above service: io_registry_entry_t) -> UInt64? {
        nearestUSBDevice(above: service, includeSelf: true)
    }

    private static func parentUSBRegistryID(_ service: io_registry_entry_t) -> UInt64? {
        nearestUSBDevice(above: service, includeSelf: false)
    }

    private static func nearestUSBDevice(above service: io_registry_entry_t, includeSelf: Bool) -> UInt64? {
        if includeSelf, IOObjectConformsTo(service, "IOUSBHostDevice") != 0 { return registryID(service) }
        var current = service
        var ownsCurrent = false
        defer { if ownsCurrent { IOObjectRelease(current) } }
        while true {
            var parent: io_registry_entry_t = 0
            guard IORegistryEntryGetParentEntry(current, kIOServicePlane, &parent) == KERN_SUCCESS else { return nil }
            if ownsCurrent { IOObjectRelease(current) }
            current = parent
            ownsCurrent = true
            if IOObjectConformsTo(current, "IOUSBHostDevice") != 0 { return registryID(current) }
        }
    }

    static func registryID(_ service: io_registry_entry_t) -> UInt64? {
        var value: UInt64 = 0
        guard IORegistryEntryGetRegistryEntryID(service, &value) == KERN_SUCCESS, value != 0 else { return nil }
        return value
    }

    private static func number(_ service: io_registry_entry_t, _ key: String) -> NSNumber? {
        IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber
    }

    private static func string(_ service: io_registry_entry_t, _ key: String) -> String? {
        IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String
    }
}
