//
//  HIDInterface.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

import Foundation

nonisolated enum HIDReportKind: Sendable { case feature, output }

/// Bytes are the exact IOHID buffer. Numbered reports include their ID at byte zero;
/// unnumbered reports contain payload only (never prepend an extra zero).
nonisolated struct HIDReport: Equatable, Sendable {
    let kind: HIDReportKind
    let reportID: UInt8
    let bytes: [UInt8]
}

nonisolated enum HIDTransportError: Error, Equatable, Sendable {
    case notOpen
    case disconnected
    case invalidLength
    case reportIDMismatch
    case unsupportedReport
    case ioKit(Int32)
    case missingMockResponse
}

nonisolated protocol HIDTransport: Sendable {
    func open() async throws
    func close() async
    func send(_ report: HIDReport) async throws
    func getFeature(reportID: UInt8, length: Int) async throws -> [UInt8]
}

nonisolated enum HIDReportValidation {
    static let allocationLimit = 65_536

    static func length(_ length: Int, maximum: Int) throws {
        guard maximum > 0 else { throw HIDTransportError.unsupportedReport }
        guard length > 0, length <= min(maximum, allocationLimit) else {
            throw HIDTransportError.invalidLength
        }
    }

    static func report(_ report: HIDReport, capabilities: HIDCapabilities) throws {
        let maximum = report.kind == .feature ? capabilities.featureReportSize : capabilities.outputReportSize
        try length(report.bytes.count, maximum: maximum)
        if report.reportID != 0, report.bytes.first != report.reportID {
            throw HIDTransportError.reportIDMismatch
        }
    }

    static func response(_ bytes: [UInt8], reportID: UInt8, requestedLength: Int) throws {
        guard !bytes.isEmpty, bytes.count <= requestedLength else { throw HIDTransportError.invalidLength }
        if reportID != 0, bytes.first != reportID { throw HIDTransportError.reportIDMismatch }
    }
}
