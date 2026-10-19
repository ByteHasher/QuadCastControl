import Testing
@testable import QuadCastControl

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct LightingControlTests {
    private var microphone: Microphone {
        Microphone(id: "audio", name: "HyperX QuadCast S", model: .quadCastS,
                   usbIdentity: .init(deviceRegistryID: 10, locationID: 1, enclosureRegistryID: nil))
    }

    private func control(_ transport: any HIDTransport) -> LightingControl {
        LightingControl(makeTransport: { _ in transport }, pause: {
            try await Task.sleep(for: .seconds(3600))
        })
    }

    @Test func constructionDoesNotOpenOrSend() async {
        let transport = MockHIDTransport()
        let lighting = control(transport)
        #expect(lighting.states.isEmpty)
        #expect(await transport.operations.isEmpty)
    }

    @Test func explicitOffSendsHeaderThenBlackAndStopCloses() async {
        let transport = MockHIDTransport()
        let lighting = control(transport)
        lighting.turnOff(microphone)
        while lighting.states["audio"] == .sending { await Task.yield() }
        #expect(lighting.states["audio"] == .active)
        let operations = await transport.operations
        #expect(operations.count == 3)
        if operations.count == 3 {
            #expect(operations[0] == .open)
            if case .send(let header) = operations[1], case .send(let color) = operations[2] {
                #expect(header.bytes.count == 64 && header.bytes[0] == 0x04 && header.bytes[1] == 0xF2)
                #expect(header.bytes[8] == 1)
                #expect(color.bytes == [0x81, 0, 0, 0, 0x81, 0, 0, 0] + [UInt8](repeating: 0, count: 56))
            } else { Issue.record("Expected a header and a black color report") }
        }
        lighting.turnOff(microphone) // Duplicate clicks do not create another writer.
        #expect(await transport.operations == operations)
        lighting.stop("audio")
        while lighting.states["audio"] == .stopping { await Task.yield() }
        #expect(lighting.states["audio"] == .idle)
        #expect(await transport.operations == operations + [.close])
    }

    @Test func missingIdentityAndOtherModelsNeverOpen() async {
        let transport = MockHIDTransport()
        let lighting = control(transport)
        var missing = microphone
        missing.usbIdentity = nil
        lighting.turnOff(missing)
        lighting.turnOff(Microphone(id: "other", name: "SoloCast", model: .soloCast,
                                   usbIdentity: microphone.usbIdentity))
        #expect(lighting.states["audio"] == .failed(.unavailable))
        #expect(lighting.states["other"] == .failed(.unavailable))
        #expect(await transport.operations.isEmpty)
    }

    @Test func openErrorIsShownWithoutSendingOrRetrying() async {
        let transport = MockHIDTransport()
        await transport.failNextOperation(with: .disconnected)
        let lighting = control(transport)
        lighting.turnOff(microphone)
        while lighting.states["audio"] == .sending { await Task.yield() }
        #expect(lighting.states["audio"] == .failed(.disconnected))
        #expect(await transport.operations == [.open])
    }

    @Test func headerFailurePreventsColorAndClosesTheTransport() async {
        let transport = ReportFailureTransport(failingSend: 1)
        let lighting = control(transport)
        lighting.turnOff(microphone)
        while lighting.states["audio"] == .sending { await Task.yield() }
        #expect(lighting.states["audio"] == .failed(.transferFailed))
        let operations = await transport.mock.operations
        #expect(operations.count == 3)
        #expect(operations.first == .open && operations.last == .close)
        if operations.count == 3, case .send(let report) = operations[1] {
            #expect(report.bytes[0] == 0x04)
        }
    }

    @Test func colorFailureClosesWithoutStartingARefreshOrRetry() async {
        let transport = ReportFailureTransport(failingSend: 2)
        let lighting = control(transport)
        lighting.turnOff(microphone)
        while lighting.states["audio"] == .sending { await Task.yield() }
        #expect(lighting.states["audio"] == .failed(.transferFailed))
        let operations = await transport.mock.operations
        #expect(operations.count == 4)
        #expect(operations.first == .open && operations.last == .close)
        if operations.count == 4, case .send(let report) = operations[2] {
            #expect(report.bytes[0] == 0x81)
        }
    }

    @Test func unplugOrChangedUSBIdentityStopsControlWithoutRestarting() async {
        for removed in [true, false] {
            let transport = MockHIDTransport()
            let lighting = control(transport)
            lighting.turnOff(microphone)
            while lighting.states["audio"] == .sending { await Task.yield() }
            var replacement = microphone
            replacement.usbIdentity = .init(deviceRegistryID: 99, locationID: 1, enclosureRegistryID: nil)
            lighting.reconcile(removed ? [] : [replacement])
            while lighting.states["audio"] == .stopping { await Task.yield() }
            #expect(lighting.states["audio"] == .idle)
            #expect(await transport.operations.last == .close)
        }
    }

    @Test func refreshLoopResendsCompletePairsAndStopsOnFailure() async {
        let transport = MockHIDTransport()
        let count = RefreshCounter()
        let lighting = LightingControl(makeTransport: { _ in transport }, pause: {
            if await count.increment() == 2 { throw LightingError.incompleteTransfer }
        })
        lighting.turnOff(microphone)
        while lighting.states["audio"] == .sending || lighting.states["audio"] == .active { await Task.yield() }
        #expect(lighting.states["audio"] == .failed(.transferFailed))
        let operations = await transport.operations
        let reports = operations.compactMap { operation -> HIDReport? in
            if case .send(let report) = operation { return report }
            return nil
        }
        #expect(reports.count == 4)
        if reports.count == 4 { #expect(reports[0] == reports[2] && reports[1] == reports[3]) }
        #expect(operations.last == .close)
    }
}

private actor ReportFailureTransport: HIDTransport {
    let mock = MockHIDTransport()
    private let failingSend: Int
    private var sends = 0
    init(failingSend: Int) { self.failingSend = failingSend }
    func open() async throws { try await mock.open() }
    func close() async { await mock.close() }
    func send(_ report: HIDReport) async throws {
        sends += 1
        if sends == failingSend { await mock.failNextOperation(with: .ioKit(-1)) }
        try await mock.send(report)
    }
    func getFeature(reportID: UInt8, length: Int) async throws -> [UInt8] {
        try await mock.getFeature(reportID: reportID, length: length)
    }
}

private actor RefreshCounter {
    private var value = 0
    func increment() -> Int { value += 1; return value }
}
