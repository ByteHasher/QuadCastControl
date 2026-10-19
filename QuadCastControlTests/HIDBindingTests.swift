import Testing
@testable import QuadCastControl

struct HIDBindingTests {
    @Test func matchesExactQuadCastSIDsOnly() {
        #expect(QuadCastSDeviceIDs.contains(vendor: 0x03f0, product: 0x028c))
        #expect(QuadCastSDeviceIDs.contains(vendor: 0x0951, product: 0x171f))
        #expect(!QuadCastSDeviceIDs.contains(vendor: 0x03f0, product: 0x02b5))
        #expect(!QuadCastSDeviceIDs.contains(vendor: 0x9999, product: 0x028c))
    }

    @Test func resolvesDocumentedUSBUIDToTheAudioFunction() throws {
        let identity = try #require(USBIdentityResolver.audioIdentity(
            uid: "AppleUSBAudioEngine:HP, Inc:HyperX QuadCast S:1124000:2,1", devices: enclosure()))
        #expect(identity.deviceRegistryID == 11)
        #expect(identity.enclosureRegistryID == 10)
        #expect(identity.locationID == 0x1124000)
        #expect(USBIdentityResolver.audioIdentity(uid: "Unrelated:1124000", devices: enclosure()) == nil)
    }

    @Test func serialNumbersMustBeUniqueAndAreNotParsedAsLocations() {
        let first = usb(id: 1, parent: nil, pid: 0x0294, location: 0x1000000, serial: "1124000")
        let second = usb(id: 2, parent: nil, pid: 0x0294, location: 0x2000000, serial: "1124000")
        let uid = "AppleUSBAudioEngine:HP, Inc:HyperX QuadCast S:1124000:2,1"
        #expect(USBIdentityResolver.audioIdentity(uid: uid, devices: [first])?.deviceRegistryID == 1)
        #expect(USBIdentityResolver.audioIdentity(uid: uid, devices: [first, second]) == nil)
    }

    @Test func splitsAudioAndHIDBehindOneInternalHubIntoOneMicrophone() throws {
        let records = enclosure()
        let audio = try #require(USBIdentityResolver.identity(for: 11, devices: records))
        let controller = try #require(USBIdentityResolver.identity(for: 12, devices: records))
        let microphones = MicrophoneHIDBinder.bind([mic(id: "audio", usb: audio)],
            interfaces: [hid(id: 100, usb: controller), hid(id: 101, usb: controller)])
        #expect(microphones.count == 1)
        #expect(microphones[0].id == "audio")
        #expect(microphones[0].hidInterfaces.map(\.id) == [100, 101])
    }

    @Test func twoIdenticalMicrophonesDoNotCrossBind() {
        let a = USBDeviceIdentity(deviceRegistryID: 11, locationID: 1, enclosureRegistryID: 10)
        let b = USBDeviceIdentity(deviceRegistryID: 21, locationID: 2, enclosureRegistryID: 20)
        let aHID = USBDeviceIdentity(deviceRegistryID: 12, locationID: 3, enclosureRegistryID: 10)
        let bHID = USBDeviceIdentity(deviceRegistryID: 22, locationID: 4, enclosureRegistryID: 20)
        let result = MicrophoneHIDBinder.bind([mic(id: "a", usb: a), mic(id: "b", usb: b)],
            interfaces: [hid(id: 200, usb: bHID), hid(id: 100, usb: aHID)])
        #expect(result.count == 2)
        #expect(result[0].hidInterfaces.map(\.id) == [100])
        #expect(result[1].hidInterfaces.map(\.id) == [200])
    }

    @Test func matchingNamesAndAnExternalHubAreNotEnough() throws {
        let external = enclosure(hubVendor: 0x1111, hubProduct: 0x2222)
        let audio = try #require(USBIdentityResolver.identity(for: 11, devices: external))
        let controller = try #require(USBIdentityResolver.identity(for: 12, devices: external))
        #expect(audio.enclosureRegistryID == nil)
        let result = MicrophoneHIDBinder.bind([mic(id: "a", usb: audio), mic(id: "b", usb: nil)],
            interfaces: [hid(id: 100, usb: controller)])
        #expect(result.allSatisfy { $0.hidInterfaces.isEmpty })
    }

    @Test func ambiguousAudioIdentitiesStayUnlinkedAndHIDNeverAddsRows() {
        let identity = USBDeviceIdentity(deviceRegistryID: 1, locationID: 1, enclosureRegistryID: nil)
        let interface = hid(id: 100, usb: identity)
        let result = MicrophoneHIDBinder.bind([mic(id: "a", usb: identity), mic(id: "b", usb: identity)],
                                            interfaces: [interface])
        #expect(result.allSatisfy { $0.hidInterfaces.isEmpty })
        #expect(MicrophoneHIDBinder.bind([], interfaces: [interface]).isEmpty)
    }

    @Test func unpluggingHIDClearsOnlyTheAssociation() {
        let identity = USBDeviceIdentity(deviceRegistryID: 1, locationID: 1, enclosureRegistryID: nil)
        let linked = MicrophoneHIDBinder.bind([mic(id: "audio", usb: identity)], interfaces: [hid(id: 100, usb: identity)])
        let disconnected = MicrophoneHIDBinder.bind(linked, interfaces: [])
        #expect(linked[0].hidInterfaces.count == 1)
        #expect(disconnected.count == 1)
        #expect(disconnected[0].id == "audio")
        #expect(disconnected[0].hidInterfaces.isEmpty)
    }

    private func enclosure(hubVendor: Int = 0x214b, hubProduct: Int = 0x7250) -> [USBRegistryDevice] {
        [
            .init(registryID: 10, parentRegistryID: nil, vendorID: hubVendor, productID: hubProduct,
                  manufacturer: "Hub", productName: "USB Hub", serialNumber: nil, locationID: 0x1120000),
            usb(id: 11, parent: 10, pid: 0x0294, location: 0x1124000),
            usb(id: 12, parent: 10, pid: 0x028c, location: 0x1121000)
        ]
    }

    private func usb(id: UInt64, parent: UInt64?, pid: Int, location: UInt32,
                     serial: String? = nil) -> USBRegistryDevice {
        .init(registryID: id, parentRegistryID: parent, vendorID: 0x03f0, productID: pid,
              manufacturer: "HP, Inc", productName: "HyperX QuadCast S", serialNumber: serial, locationID: location)
    }

    private func mic(id: String, usb: USBDeviceIdentity?) -> Microphone {
        .init(id: id, name: "HyperX QuadCast S", model: .quadCastS, usbIdentity: usb)
    }

    private func hid(id: UInt64, usb: USBDeviceIdentity?) -> HIDInterface {
        .init(id: id, vendorID: 0x03f0, productID: 0x028c, usagePage: 0x0c, usage: 1,
              capabilities: .mock, usbIdentity: usb)
    }
}
