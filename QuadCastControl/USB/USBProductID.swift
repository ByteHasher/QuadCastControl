//
//  USBProductID.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

nonisolated struct USBProductID: Hashable, Sendable {
    let vendor: Int
    let product: Int
}
