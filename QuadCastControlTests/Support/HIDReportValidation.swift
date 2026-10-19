@testable import QuadCastControl

/// Framing and capability validation for test transports.
nonisolated enum HIDReportValidation {
    static let allocationLimit = 65_536

    static func length(_ length: Int, maximum: Int) throws {
        guard maximum > 0 else { throw HIDTransportError.unsupportedReport }
        guard length > 0, length <= min(maximum, allocationLimit) else {
            throw HIDTransportError.invalidLength
        }
    }

    static func report(_ report: HIDReport, capabilities: HIDCapabilities) throws {
        let maximum = report.kind == .feature ? capabilities.featureReportSize : capabilities.outputReportSize
        try length(report.bytes.count, maximum: maximum)
        if report.reportID != 0, report.bytes.first != report.reportID {
            throw HIDTransportError.reportIDMismatch
        }
    }

    static func response(_ bytes: [UInt8], reportID: UInt8, requestedLength: Int) throws {
        guard !bytes.isEmpty, bytes.count <= requestedLength else { throw HIDTransportError.invalidLength }
        if reportID != 0, bytes.first != reportID { throw HIDTransportError.reportIDMismatch }
    }
}
