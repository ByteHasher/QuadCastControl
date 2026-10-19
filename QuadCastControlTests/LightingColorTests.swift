import Testing
@testable import QuadCastControl

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct LightingColorTests {
    private var microphone: Microphone {
        Microphone(id: "audio", name: "QuadCast S", model: .quadCastS,
            usbIdentity: .init(deviceRegistryID: 1, locationID: nil, enclosureRegistryID: nil))
    }

    @Test func sendsSelectedColorWithRoundedBrightness() async {
        let transport = MockHIDTransport()
        let gate = ColorFrameGate()
        let lighting = LightingControl(makeTransport: { _ in transport }, pause: { try await gate.wait() })
        lighting.apply(microphone, color: RGBColor(red: 255, green: 3, blue: 254), brightnessPercent: 50)
        while lighting.states["audio"] == .sending { await Task.yield() }
        #expect(lighting.activeColors["audio"] == RGBColor(red: 128, green: 2, blue: 127))
        let reports = await sentColors(transport)
        #expect(reports == [[0x81, 128, 2, 127, 0x81, 128, 2, 127] + [UInt8](repeating: 0, count: 56)])
        lighting.stopAll()
        while lighting.states["audio"] == .stopping { await Task.yield() }
        #expect(lighting.activeColors["audio"] == nil)
    }

    @Test func liveEditsAndOffUseOneOpenTransport() async {
        let transport = MockHIDTransport()
        let gate = ColorFrameGate()
        let lighting = LightingControl(makeTransport: { _ in transport }, pause: { try await gate.wait() })
        let red = RGBColor(red: 255, green: 0, blue: 0)
        let blue = RGBColor(red: 0, green: 0, blue: 255)
        lighting.apply(microphone, color: red, brightnessPercent: 100)
        while lighting.states["audio"] == .sending { await Task.yield() }

        lighting.apply(microphone, color: blue, brightnessPercent: 100)
        #expect(lighting.activeColors["audio"] == red) // Not yet sent.
        gate.advance()
        while lighting.activeColors["audio"] != blue { await Task.yield() }

        lighting.turnOff(microphone)
        gate.advance()
        while lighting.activeColors["audio"] != .off { await Task.yield() }

        lighting.apply(microphone, color: red, brightnessPercent: 100)
        gate.advance()
        while lighting.activeColors["audio"] != red { await Task.yield() }

        let colors = await sentColors(transport)
        #expect(colors.map { Array($0.prefix(8)) } == [
            [0x81, 255, 0, 0, 0x81, 255, 0, 0],
            [0x81, 0, 0, 255, 0x81, 0, 0, 255],
            [0x81, 0, 0, 0, 0x81, 0, 0, 0],
            [0x81, 255, 0, 0, 0x81, 255, 0, 0]
        ])
        lighting.stopAll()
        while lighting.states["audio"] == .stopping { await Task.yield() }
        let operations = await transport.operations
        #expect(operations.filter { $0 == .open }.count == 1)
        #expect(operations.filter { $0 == .close }.count == 1)
    }

    @Test func zeroBrightnessSendsBlackWithoutLosingOriginalColor() async {
        let transport = MockHIDTransport()
        let gate = ColorFrameGate()
        let lighting = LightingControl(makeTransport: { _ in transport }, pause: { try await gate.wait() })
        let color = RGBColor(red: 13, green: 127, blue: 255)
        lighting.apply(microphone, color: color, brightnessPercent: 0)
        while lighting.states["audio"] == .sending { await Task.yield() }
        #expect(lighting.activeColors["audio"] == .off)
        lighting.apply(microphone, color: color, brightnessPercent: 100)
        gate.advance()
        while lighting.activeColors["audio"] != color { await Task.yield() }
        let colors = await sentColors(transport)
        #expect(colors.map { Array($0.prefix(8)) } == [
            [0x81, 0, 0, 0, 0x81, 0, 0, 0],
            [0x81, 13, 127, 255, 0x81, 13, 127, 255]
        ])
        lighting.stopAll()
        while lighting.states["audio"] == .stopping { await Task.yield() }
    }

    @Test func editBetweenHeaderAndPayloadTakesEffectOnlyOnNextFrame() async {
        let headerGate = ColorFrameGate()
        let refreshGate = ColorFrameGate()
        let transport = PausingColorTransport(headerGate: headerGate)
        let lighting = LightingControl(makeTransport: { _ in transport }, pause: { try await refreshGate.wait() })
        let red = RGBColor(red: 255, green: 0, blue: 0)
        let blue = RGBColor(red: 0, green: 0, blue: 255)
        lighting.apply(microphone, color: red, brightnessPercent: 100)
        while !(await transport.headerPaused) { await Task.yield() }
        lighting.apply(microphone, color: blue, brightnessPercent: 100)
        headerGate.advance()
        while lighting.states["audio"] == .sending { await Task.yield() }
        #expect(lighting.activeColors["audio"] == red)
        let first = await sentColors(transport.mock)
        #expect(first.map { Array($0.prefix(8)) } == [[0x81, 255, 0, 0, 0x81, 255, 0, 0]])
        refreshGate.advance()
        while lighting.activeColors["audio"] != blue { await Task.yield() }
        lighting.stopAll()
        while lighting.states["audio"] == .stopping { await Task.yield() }
    }

    @Test func applyingDuringStopDoesNotReopenOrQueueARestart() async {
        let transport = MockHIDTransport()
        let gate = ColorFrameGate()
        let lighting = LightingControl(makeTransport: { _ in transport }, pause: { try await gate.wait() })
        lighting.turnOff(microphone)
        while lighting.states["audio"] == .sending { await Task.yield() }
        lighting.stop("audio")
        lighting.apply(microphone, color: RGBColor(red: 255, green: 0, blue: 0), brightnessPercent: 100)
        while lighting.states["audio"] == .stopping { await Task.yield() }
        #expect(lighting.states["audio"] == .idle)
        let operations = await transport.operations
        #expect(operations.filter { $0 == .open }.count == 1)
        #expect(operations.last == .close)
    }

    private func sentColors(_ transport: MockHIDTransport) async -> [[UInt8]] {
        await transport.operations.compactMap {
            if case .send(let report) = $0, report.bytes.first == 0x81 { return report.bytes }
            return nil
        }
    }
}

nonisolated private struct ColorFrameGate: Sendable {
    private let stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation
    init() { (stream, continuation) = AsyncStream<Void>.makeStream() }
    func advance() { continuation.yield(()) }
    func wait() async throws {
        for await _ in stream { return }
        throw CancellationError()
    }
}

private actor PausingColorTransport: HIDTransport {
    let mock = MockHIDTransport()
    private let headerGate: ColorFrameGate
    private(set) var headerPaused = false
    init(headerGate: ColorFrameGate) { self.headerGate = headerGate }
    func open() async throws { try await mock.open() }
    func close() async { await mock.close() }
    func send(_ report: HIDReport) async throws {
        try await mock.send(report)
        if report.bytes.first == 0x04, !headerPaused {
            headerPaused = true
            try await headerGate.wait()
        }
    }
    func getFeature(reportID: UInt8, length: Int) async throws -> [UInt8] {
        try await mock.getFeature(reportID: reportID, length: length)
    }
}
