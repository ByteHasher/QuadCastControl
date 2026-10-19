//
//  QuadCastSColorPacketBuilder.swift
//  QuadCastControl
//
//  Created by ByteHasher on 19.10.2026.
//

/// Pure encoder for the live-color format in Docs/PROTOCOL.md.
/// It does not discover devices, open a transport, send reports or schedule frames.
nonisolated enum QuadCastSColorPacketBuilder {
    /// Wire values from Docs/PROTOCOL.md, Published live-color format.
    private enum Wire {
        static let reportLength = 64
        static let reportID: UInt8 = 0
        static let marker: UInt8 = 0x04
        static let liveColorCommand: UInt8 = 0xF2
        static let zoneMarker: UInt8 = 0x81
        static let packetCountOffset = 8
        static let singleColorPacketCount: UInt8 = 0x01
    }

    static func solid(_ color: RGBColor) -> [HIDReport] {
        frame(upper: color, lower: color)
    }

    /// Returns one header followed by one two-zone color packet.
    /// The caller must verify the device/interface capabilities before any transfer.
    static func frame(upper: RGBColor, lower: RGBColor) -> [HIDReport] {
        var header = [UInt8](repeating: 0, count: Wire.reportLength)
        header[0] = Wire.marker
        header[1] = Wire.liveColorCommand
        header[Wire.packetCountOffset] = Wire.singleColorPacketCount

        var colors: [UInt8] = [
            Wire.zoneMarker, upper.red, upper.green, upper.blue,
            Wire.zoneMarker, lower.red, lower.green, lower.blue
        ]
        colors += [UInt8](repeating: 0, count: Wire.reportLength - colors.count)

        // Unnumbered Feature reports: report ID is metadata, never a payload prefix.
        return [
            HIDReport(kind: .feature, reportID: Wire.reportID, bytes: header),
            HIDReport(kind: .feature, reportID: Wire.reportID, bytes: colors)
        ]
    }
}
