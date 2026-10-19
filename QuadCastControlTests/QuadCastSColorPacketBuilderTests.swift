import Testing
@testable import QuadCastControl

struct QuadCastSColorPacketBuilderTests {
    // Independent byte fixtures from the documented wire layout, not another encoder.
    private let expectedHeader: [UInt8] = [
        0x04, 0xF2, 0, 0, 0, 0, 0, 0,
        0x01, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0
    ]

    @Test func distinctZonesMatchBothCompleteWirePackets() {
        let reports = QuadCastSColorPacketBuilder.frame(
            upper: RGBColor(red: 0x12, green: 0x34, blue: 0x56),
            lower: RGBColor(red: 0xAB, green: 0xCD, blue: 0xEF)
        )
        let expectedColors: [UInt8] = [
            0x81, 0x12, 0x34, 0x56, 0x81, 0xAB, 0xCD, 0xEF,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0
        ]

        // Whole-report equality also checks ordering, report kind/ID, exact length,
        // channel and zone order, zero padding, and the absence of an extra ID byte.
        #expect(reports == [
            HIDReport(kind: .feature, reportID: 0, bytes: expectedHeader),
            HIDReport(kind: .feature, reportID: 0, bytes: expectedColors)
        ])
    }

    @Test(arguments: [
        SolidColorFixture(color: .off,
                          prefix: [0x81, 0, 0, 0, 0x81, 0, 0, 0]),
        SolidColorFixture(color: RGBColor(red: 255, green: 255, blue: 255),
                          prefix: [0x81, 255, 255, 255, 0x81, 255, 255, 255]),
        SolidColorFixture(color: RGBColor(red: 255, green: 0, blue: 0),
                          prefix: [0x81, 255, 0, 0, 0x81, 255, 0, 0]),
        SolidColorFixture(color: RGBColor(red: 0, green: 255, blue: 0),
                          prefix: [0x81, 0, 255, 0, 0x81, 0, 255, 0]),
        SolidColorFixture(color: RGBColor(red: 0, green: 0, blue: 255),
                          prefix: [0x81, 0, 0, 255, 0x81, 0, 0, 255]),
        SolidColorFixture(color: RGBColor(red: 1, green: 127, blue: 254),
                          prefix: [0x81, 1, 127, 254, 0x81, 1, 127, 254])
    ])
    func solidColorPreservesChannelsInBothZones(fixture: SolidColorFixture) {
        let reports = QuadCastSColorPacketBuilder.solid(fixture.color)
        let expectedColors = fixture.prefix + [UInt8](repeating: 0, count: 56)

        #expect(reports == [
            HIDReport(kind: .feature, reportID: 0, bytes: expectedHeader),
            HIDReport(kind: .feature, reportID: 0, bytes: expectedColors)
        ])
    }
}

nonisolated struct SolidColorFixture: Sendable {
    let color: RGBColor
    let prefix: [UInt8]
}
