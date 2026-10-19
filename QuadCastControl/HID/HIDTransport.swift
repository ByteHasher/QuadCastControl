//
//  HIDTransport.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

import Foundation

nonisolated enum HIDReportKind: Sendable { case feature, output }

/// HID report framing. Numbered reports include their ID at byte zero;
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
}

nonisolated protocol HIDTransport: Sendable {
    func open() async throws
    func close() async
    func send(_ report: HIDReport) async throws
    func getFeature(reportID: UInt8, length: Int) async throws -> [UInt8]
}
