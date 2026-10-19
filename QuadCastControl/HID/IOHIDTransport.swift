//
//  IOHIDTransport.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

import Foundation
import IOKit.hid

/// An immutable, retained CF handle. Transport operations are serialized by IOHIDTransport.
nonisolated final class HIDDeviceReference: @unchecked Sendable {
    let device: IOHIDDevice
    init(_ device: IOHIDDevice) { self.device = device }
}

actor IOHIDTransport: HIDTransport {
    private let reference: HIDDeviceReference
    private let capabilities: HIDCapabilities
    private var isOpen = false
    private var connected = true

    init(device: HIDDeviceReference, capabilities: HIDCapabilities) {
        reference = device
        self.capabilities = capabilities
    }

    func open() throws {
        guard connected else { throw HIDTransportError.disconnected }
        guard !isOpen else { return }
        // Shared access only. No capture/seizure of the microphone or its audio interfaces.
        try check(IOHIDDeviceOpen(reference.device, IOOptionBits(kIOHIDOptionsTypeNone)))
        isOpen = true
    }

    func close() {
        guard isOpen else { return }
        IOHIDDeviceClose(reference.device, IOOptionBits(kIOHIDOptionsTypeNone))
        isOpen = false
    }

    func disconnect() { close(); connected = false }

    func send(_ report: HIDReport) throws {
        try requireOpen()
        try HIDReportValidation.report(report, capabilities: capabilities)
        let type = report.kind == .feature ? kIOHIDReportTypeFeature : kIOHIDReportTypeOutput
        let result = report.bytes.withUnsafeBufferPointer { buffer in
            IOHIDDeviceSetReport(reference.device, type, CFIndex(report.reportID), buffer.baseAddress!, buffer.count)
        }
        try check(result)
    }

    func getFeature(reportID: UInt8, length: Int) throws -> [UInt8] {
        try requireOpen()
        try HIDReportValidation.length(length, maximum: capabilities.featureReportSize)
        var bytes = [UInt8](repeating: 0, count: length)
        if reportID != 0 { bytes[0] = reportID }
        var count = length
        let result = bytes.withUnsafeMutableBufferPointer { buffer in
            IOHIDDeviceGetReport(reference.device, kIOHIDReportTypeFeature,
                                CFIndex(reportID), buffer.baseAddress!, &count)
        }
        try check(result)
        guard count > 0, count <= length else { throw HIDTransportError.invalidLength }
        let response = Array(bytes.prefix(count))
        try HIDReportValidation.response(response, reportID: reportID, requestedLength: length)
        return response
    }

    private func requireOpen() throws {
        guard connected else { throw HIDTransportError.disconnected }
        guard isOpen else { throw HIDTransportError.notOpen }
    }

    private func check(_ status: IOReturn) throws {
        if status == kIOReturnNoDevice { connected = false; isOpen = false; throw HIDTransportError.disconnected }
        guard status == kIOReturnSuccess else { throw HIDTransportError.ioKit(status) }
    }
}
