import Testing
@testable import QuadCastControl

struct QuadCastSLightingTargetTests {
    private func device(_ id: UInt64, parent: UInt64? = nil, vendor: Int = 0x03F0,
                        product: Int = 0x028C) -> USBRegistryDevice {
        .init(registryID: id, parentRegistryID: parent, vendorID: vendor, productID: product,
              manufacturer: "HP, Inc", productName: "QuadCast S", serialNumber: nil, locationID: nil)
    }

    @Test func resolvesTheVerifiedSplitControllerWithoutUsingTheAudioPID() throws {
        let devices = [device(1, vendor: 0x214B, product: 0x7250),
                       device(2, parent: 1), device(3, parent: 1, product: 0x0294)]
        let identity = USBDeviceIdentity(deviceRegistryID: 3, locationID: nil, enclosureRegistryID: 1)
        #expect(try QuadCastSLightingTarget.controller(for: identity, devices: devices) == 2)
    }

    @Test func directIdentitySelectsOnlyItsOwnController() throws {
        let identity = USBDeviceIdentity(deviceRegistryID: 2, locationID: nil, enclosureRegistryID: nil)
        #expect(try QuadCastSLightingTarget.controller(for: identity, devices: [device(1), device(2)]) == 2)
    }

    @Test func missingUnknownAndAmbiguousTargetsAreRejected() {
        #expect(throws: LightingError.unavailable) {
            try QuadCastSLightingTarget.controller(for: nil, devices: [device(1)])
        }
        let identity = USBDeviceIdentity(deviceRegistryID: 1, locationID: nil, enclosureRegistryID: nil)
        for devices in [[device(1, product: 0x0294)], [device(1), device(1)]] {
            #expect(throws: LightingError.unavailable) {
                try QuadCastSLightingTarget.controller(for: identity, devices: devices)
            }
        }
    }

    @Test func descriptorGateRequiresExactUnnumberedFeatureLayout() throws {
        let expected: [UInt8] = [
            0x06, 0x90, 0xFF, 0x0A, 0x00, 0xFF, 0xA1, 0x01,
            0x15, 0x00, 0x26, 0xFF, 0x00, 0x75, 0x08, 0x95,
            0x40, 0x09, 0x02, 0x81, 0x02, 0x09, 0x03, 0x91,
            0x02, 0x0A, 0x00, 0xFF, 0xB1, 0x02, 0xC0
        ]
        try QuadCastSLightingTarget.validateDescriptor(expected)
        for invalid in [[], Array(expected.dropLast()), expected + [0], [0x85, 0x07] + expected] {
            #expect(throws: LightingError.unsupportedDescriptor) {
                try QuadCastSLightingTarget.validateDescriptor(invalid)
            }
        }
        var wrongSize = expected
        wrongSize[16] = 0x20
        #expect(throws: LightingError.unsupportedDescriptor) {
            try QuadCastSLightingTarget.validateDescriptor(wrongSize)
        }
    }
}
