//
//  USBQuadCastSTransport.swift
//  QuadCastControl
//
//  Created by ByteHasher on 19.10.2026.
//

import Foundation
import IOKit
import IOUSBHost
import OSLog

/// Interface-0 Feature transport for the documented QuadCast S layout.
/// Created without I/O; only explicit open() obtains the RGB interface.
actor USBQuadCastSTransport: HIDTransport {
    private static let logger = Logger(subsystem: "QuadCastControl", category: "USBLighting")
    private let identity: USBDeviceIdentity?
    private var interface: IOUSBHostInterface?

    init(identity: USBDeviceIdentity?) { self.identity = identity }

    func open() throws {
        guard interface == nil else { return }
        let controller = try QuadCastSLightingTarget.controller(for: identity, devices: USBRegistry.devices())
        let service = try findInterface(controller: controller)
        defer { IOObjectRelease(service) }
        // No capture/seize, alternate-setting changes, or audio interface access.
        let candidate: IOUSBHostInterface
        do {
            candidate = try IOUSBHostInterface(__ioService: service, options: [], queue: nil, interestHandler: nil)
        } catch {
            let failure = error as NSError
            Self.logger.error("RGB interface open failed: \(failure.domain, privacy: .public), code \(failure.code)")
            throw LightingError.openFailed
        }
        do {
            let descriptor = candidate.interfaceDescriptor.pointee
            guard descriptor.bInterfaceNumber == 0, descriptor.bInterfaceClass == 3,
                  descriptor.bAlternateSetting == 0 else { throw LightingError.unsupportedDescriptor }
            let bytes = try transfer(on: candidate, type: 0x81, request: 0x06, value: 0x2200,
                                     bytes: [UInt8](repeating: 0, count: QuadCastSLightingTarget.reportDescriptor.count + 1),
                                     allowShortRead: true)
            try QuadCastSLightingTarget.validateDescriptor(bytes)
            interface = candidate
        } catch {
            candidate.destroy()
            throw error
        }
    }

    func close() { interface?.destroy(); interface = nil }

    func send(_ report: HIDReport) throws {
        guard let interface else { throw HIDTransportError.notOpen }
        guard report.kind == .feature, report.reportID == 0 else { throw HIDTransportError.unsupportedReport }
        guard report.bytes.count == 64 else { throw HIDTransportError.invalidLength }
        _ = try transfer(on: interface, type: 0x21, request: 0x09, value: 0x0300, bytes: report.bytes)
    }

    func getFeature(reportID: UInt8, length: Int) throws -> [UInt8] {
        // Status/persistence commands are outside this transport's supported operation.
        throw HIDTransportError.unsupportedReport
    }

    private func transfer(on interface: IOUSBHostInterface, type: UInt8, request: UInt8,
                          value: UInt16, bytes: [UInt8], allowShortRead: Bool = false) throws -> [UInt8] {
        var setup = IOUSBDeviceRequest()
        setup.bmRequestType = type
        setup.bRequest = request
        setup.wValue = value
        setup.wIndex = 0
        setup.wLength = UInt16(bytes.count)
        let data = NSMutableData(data: Data(bytes))
        var transferred = 0
        // Bounded application timeout; not a measured device response time.
        try interface.__send(setup, data: data, bytesTransferred: &transferred, completionTimeout: 2)
        guard transferred > 0, transferred <= bytes.count,
              allowShortRead || transferred == bytes.count else { throw LightingError.incompleteTransfer }
        // Ask for one descriptor byte beyond the known length, so a longer descriptor
        // sharing the same prefix cannot pass the exact-layout gate.
        return Array((data as Data).prefix(transferred))
    }

    private func findInterface(controller: UInt64) throws -> io_service_t {
        var iterator: io_iterator_t = 0
        let status = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOUSBHostInterface"), &iterator)
        guard status == KERN_SUCCESS else { throw HIDTransportError.ioKit(status) }
        defer { IOObjectRelease(iterator) }
        var matches: [io_service_t] = []
        while true {
            let service = IOIteratorNext(iterator)
            guard service != 0 else { break }
            let number = IORegistryEntryCreateCFProperty(service, "bInterfaceNumber" as CFString,
                kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber
            let usbClass = IORegistryEntryCreateCFProperty(service, "bInterfaceClass" as CFString,
                kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber
            if number?.intValue == 0, usbClass?.intValue == 3,
               USBRegistry.deviceRegistryID(above: service) == controller {
                matches.append(service)
            } else { IOObjectRelease(service) }
        }
        guard matches.count == 1 else {
            matches.forEach { IOObjectRelease($0) }
            throw LightingError.unavailable
        }
        return matches[0]
    }
}
