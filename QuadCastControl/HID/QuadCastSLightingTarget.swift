import Foundation

nonisolated enum LightingError: Error, Equatable, Sendable {
    case unavailable
    case openFailed
    case unsupportedDescriptor
    case incompleteTransfer
}

nonisolated enum QuadCastSLightingTarget {
    /// Identity must come from CoreAudio binding, never a product-name or first-device match.
    static func controller(for identity: USBDeviceIdentity?, devices: [USBRegistryDevice]) throws -> UInt64 {
        guard let identity else { throw LightingError.unavailable }
        let matches = devices.filter { device in
            guard QuadCastSDeviceIDs.contains(vendor: device.vendorID, product: device.productID),
                  let candidate = USBIdentityResolver.identity(for: device.registryID, devices: devices) else { return false }
            return candidate.deviceRegistryID == identity.deviceRegistryID
                || (identity.enclosureRegistryID != nil && candidate.enclosureRegistryID == identity.enclosureRegistryID)
        }
        guard matches.count == 1 else { throw LightingError.unavailable }
        return matches[0].registryID
    }

    /// Published interface-0 descriptor: FF90/FF00, unnumbered 64-byte reports.
    /// See Docs/PROTOCOL.md. Other collections/revisions are not authorized by VID/PID alone.
    static let reportDescriptor: [UInt8] = [
        0x06, 0x90, 0xFF, 0x0A, 0x00, 0xFF, 0xA1, 0x01,
        0x15, 0x00, 0x26, 0xFF, 0x00, 0x75, 0x08, 0x95,
        0x40, 0x09, 0x02, 0x81, 0x02, 0x09, 0x03, 0x91,
        0x02, 0x0A, 0x00, 0xFF, 0xB1, 0x02, 0xC0
    ]

    static func validateDescriptor(_ bytes: [UInt8]) throws {
        guard bytes == reportDescriptor else { throw LightingError.unsupportedDescriptor }
    }
}
