import Testing
@testable import QuadCastControl

@MainActor
struct MicrophoneHIDDiscoveryTests {
    @Test(.timeLimit(.minutes(1)))
    func audioScanAndHIDProviderProduceOneRowWithBoundInterfaceMetadata() async {
        let identity = USBDeviceIdentity(deviceRegistryID: 1, locationID: 1, enclosureRegistryID: nil)
        let microphone = Microphone(id: "audio", name: "HyperX QuadCast S", model: .quadCastS, usbIdentity: identity)
        let interface = HIDInterface(id: 100, vendorID: 0x03f0, productID: 0x028c,
            usagePage: 0x0c, usage: 1, capabilities: .mock, usbIdentity: identity)
        let hid = FakeHIDDiscovery(interfaces: [interface])
        let discovery = MicrophoneDiscovery(scanner: SnapshotScanner(devices: [microphone]), hid: hid)

        discovery.refresh()
        while discovery.isScanning { await Task.yield() }
        #expect(discovery.microphones.count == 1)
        #expect(discovery.microphones[0].id == "audio")
        #expect(discovery.microphones[0].hidInterfaces.map(\.id) == [100])

        hid.interfaces = []
        discovery.refresh()
        while discovery.isScanning { await Task.yield() }
        #expect(discovery.microphones.count == 1)
        #expect(discovery.microphones[0].hidInterfaces.isEmpty)
    }

    @Test(.timeLimit(.minutes(1)))
    func failedAudioScanDoesNotExposeHIDOnlyMicrophones() async {
        let interface = HIDInterface(id: 100, vendorID: 0x03f0, productID: 0x028c,
            usagePage: 0x0c, usage: 1, capabilities: .mock, usbIdentity: nil)
        let hid = FakeHIDDiscovery(interfaces: [interface])
        let discovery = MicrophoneDiscovery(scanner: FailingScanner(), hid: hid)
        discovery.refresh()
        while discovery.isScanning { await Task.yield() }
        #expect(discovery.scanFailed)
        #expect(discovery.microphones.isEmpty)
    }
}

nonisolated private struct SnapshotScanner: MicrophoneScanning {
    let devices: [Microphone]
    func scan() throws -> [Microphone] { devices }
}

nonisolated private struct FailingScanner: MicrophoneScanning {
    func scan() throws -> [Microphone] { throw MicrophoneScanError.unexpectedPropertySize }
}

@MainActor
private final class FakeHIDDiscovery: HIDDiscovering {
    var interfaces: [HIDInterface]
    var state: HIDDiscoveryState = .running
    var onChange: (@MainActor () -> Void)?

    init(interfaces: [HIDInterface]) { self.interfaces = interfaces }
    func start() { state = .running }
    func stop() { interfaces = []; state = .stopped }
    func refresh() {}
}
