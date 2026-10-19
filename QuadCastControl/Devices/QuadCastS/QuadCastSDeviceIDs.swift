//
//  QuadCastSDeviceIDs.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

nonisolated enum QuadCastSDeviceIDs {
    // USB identifiers are hardware facts, not permission to send vendor commands.
    static let controllers: Set<USBProductID> = [
        .init(vendor: 0x0951, product: 0x171f),
        .init(vendor: 0x03f0, product: 0x0f8b),
        .init(vendor: 0x03f0, product: 0x028c),
        .init(vendor: 0x03f0, product: 0x048c),
        .init(vendor: 0x03f0, product: 0x068c)
    ]

    static func contains(vendor: Int, product: Int) -> Bool {
        controllers.contains(.init(vendor: vendor, product: product))
    }
}
