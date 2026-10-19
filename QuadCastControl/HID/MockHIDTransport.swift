//
//  MockHIDTransport.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

import Foundation

nonisolated enum HIDOperation: Equatable, Sendable {
    case open
    case close
    case send(HIDReport)
    case getFeature(reportID: UInt8, length: Int)
}

actor MockHIDTransport: HIDTransport {
    private let capabilities: HIDCapabilities
    private(set) var operations: [HIDOperation] = []
    private var isOpen = false
    private var connected = true
    private var responses: [UInt8: [[UInt8]]] = [:]
    private var nextError: HIDTransportError?

    init(capabilities: HIDCapabilities = .mock) { self.capabilities = capabilities }

    func enqueueFeatureResponse(_ bytes: [UInt8], reportID: UInt8) {
        responses[reportID, default: []].append(bytes)
    }

    func failNextOperation(with error: HIDTransportError) { nextError = error }

    func disconnect() { connected = false; isOpen = false }

    func open() throws {
        guard connected else { throw HIDTransportError.disconnected }
        guard !isOpen else { return }
        try perform(.open)
        isOpen = true
    }

    func close() {
        guard isOpen else { return }
        operations.append(.close)
        isOpen = false
    }

    func send(_ report: HIDReport) throws {
        try requireOpen()
        try HIDReportValidation.report(report, capabilities: capabilities)
        try perform(.send(report))
    }

    func getFeature(reportID: UInt8, length: Int) throws -> [UInt8] {
        try requireOpen()
        try HIDReportValidation.length(length, maximum: capabilities.featureReportSize)
        try perform(.getFeature(reportID: reportID, length: length))
        guard var queue = responses[reportID], !queue.isEmpty else { throw HIDTransportError.missingMockResponse }
        let response = queue.removeFirst()
        responses[reportID] = queue
        try HIDReportValidation.response(response, reportID: reportID, requestedLength: length)
        return response
    }

    private func requireOpen() throws {
        guard connected else { throw HIDTransportError.disconnected }
        guard isOpen else { throw HIDTransportError.notOpen }
    }

    private func perform(_ operation: HIDOperation) throws {
        operations.append(operation)
        if let error = nextError { nextError = nil; throw error }
    }
}
