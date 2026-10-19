import Testing
@testable import QuadCastControl

@MainActor
struct LightingOpenErrorTests {
    @Test(.timeLimit(.minutes(1)))
    func nativeOpenFailureIsNotReportedAsAColorTransferFailure() async {
        let transport = OpenFailureTransport()
        let lighting = LightingControl(makeTransport: { _ in transport })
        lighting.turnOff(Microphone(id: "audio", name: "QuadCast S", model: .quadCastS,
            usbIdentity: .init(deviceRegistryID: 1, locationID: nil, enclosureRegistryID: nil)))
        while lighting.states["audio"] == .sending { await Task.yield() }
        #expect(lighting.states["audio"] == .failed(.openFailed))
        #expect(await transport.sendCount == 0)
        #expect(await transport.closed)
    }
}

private actor OpenFailureTransport: HIDTransport {
    private(set) var sendCount = 0
    private(set) var closed = false
    func open() throws { throw LightingError.openFailed }
    func close() { closed = true }
    func send(_ report: HIDReport) { sendCount += 1 }
    func getFeature(reportID: UInt8, length: Int) throws -> [UInt8] { throw LightingError.openFailed }
}
