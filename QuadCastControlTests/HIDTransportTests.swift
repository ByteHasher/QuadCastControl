import Testing
@testable import QuadCastControl

struct HIDTransportTests {
    @Test func discoveryAndConstructionDoNotSendReports() async {
        let transport = MockHIDTransport()
        #expect(await transport.operations.isEmpty)
        await #expect(throws: HIDTransportError.notOpen) {
            try await transport.send(.init(kind: .feature, reportID: 0, bytes: [0x11]))
        }
        #expect(await transport.operations.isEmpty)
    }

    @Test func unnumberedReportsKeepTheFirstPayloadByte() async throws {
        let transport = MockHIDTransport()
        try await transport.open()
        let packet = HIDReport(kind: .feature, reportID: 0, bytes: [0x11, 0x22, 0x33])
        try await transport.send(packet)
        await transport.close()
        #expect(await transport.operations == [.open, .send(packet), .close])
    }

    @Test func numberedReportsRoundTripWithoutDuplicatingTheirID() async throws {
        let transport = MockHIDTransport()
        try await transport.open()
        let packet = HIDReport(kind: .feature, reportID: 3, bytes: [3, 0x11])
        try await transport.send(packet)
        await transport.enqueueFeatureResponse([3, 0x22], reportID: 3)
        #expect(try await transport.getFeature(reportID: 3, length: 64) == [3, 0x22])
        #expect(await transport.operations == [.open, .send(packet), .getFeature(reportID: 3, length: 64)])
    }

    @Test func rejectsMalformedPacketsBeforeAnyTraffic() async throws {
        let transport = MockHIDTransport()
        try await transport.open()
        await #expect(throws: HIDTransportError.reportIDMismatch) {
            try await transport.send(.init(kind: .feature, reportID: 3, bytes: [4, 0x11]))
        }
        for length in [0, 65, Int.max] {
            await #expect(throws: HIDTransportError.invalidLength) {
                _ = try await transport.getFeature(reportID: 0, length: length)
            }
        }
        #expect(await transport.operations == [.open])
    }

    @Test func missingFeatureCapabilityBlocksOnlyFeatureTraffic() async throws {
        let transport = MockHIDTransport(capabilities: .init(inputReportSize: 64, outputReportSize: 64, featureReportSize: 0))
        try await transport.open()
        await #expect(throws: HIDTransportError.unsupportedReport) {
            _ = try await transport.getFeature(reportID: 0, length: 64)
        }
        let output = HIDReport(kind: .output, reportID: 0, bytes: [0x11])
        try await transport.send(output)
        #expect(await transport.operations == [.open, .send(output)])
    }

    @Test func responseMustMatchItsNumberedReportID() async throws {
        let transport = MockHIDTransport()
        try await transport.open()
        await transport.enqueueFeatureResponse([4, 0x22], reportID: 3)
        await #expect(throws: HIDTransportError.reportIDMismatch) {
            _ = try await transport.getFeature(reportID: 3, length: 64)
        }
    }

    @Test func injectedIOErrorIsPropagatedWithoutRetrying() async throws {
        let transport = MockHIDTransport()
        try await transport.open()
        await transport.failNextOperation(with: .ioKit(-1))
        let packet = HIDReport(kind: .output, reportID: 0, bytes: [0x11])
        await #expect(throws: HIDTransportError.ioKit(-1)) { try await transport.send(packet) }
        #expect(await transport.operations == [.open, .send(packet)])
    }

    @Test func closedAndDisconnectedHandlesCannotBeUsed() async throws {
        let transport = MockHIDTransport()
        try await transport.open()
        await transport.close()
        await #expect(throws: HIDTransportError.notOpen) {
            _ = try await transport.getFeature(reportID: 0, length: 1)
        }
        await transport.disconnect()
        await #expect(throws: HIDTransportError.disconnected) { try await transport.open() }
        #expect(await transport.operations == [.open, .close])
    }
}
