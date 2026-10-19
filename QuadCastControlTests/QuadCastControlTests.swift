//
//  QuadCastControlTests.swift
//  QuadCastControlTests
//
//  Created by ByteHasher on 18.10.2026.
//

import Foundation
import Testing
@testable import QuadCastControl

struct QuadCastControlTests {
    @Test func distinguishesQuadCastRevisions() {
        for model in MicrophoneModel.allCases {
            #expect(MicrophoneModel.identify(name: "HyperX \(model.rawValue)",
                modelName: "", manufacturer: "") == model)
        }
    }

    @Test func ignoresOtherHyperXProductsAndUnrelatedDevices() {
        for name in ["HyperX Cloud II", "HyperX QuadCast 20", "Other QuadCast S", "MacBook Pro Microphone"] {
            #expect(MicrophoneModel.identify(name: name, modelName: "", manufacturer: "") == nil)
        }
    }

    @Test func modelMetadataSupportsRenamedMicrophones() {
        #expect(MicrophoneModel.identify(name: "Desk microphone", modelName: "QuadCast S",
                                        manufacturer: "HP, Inc.") == .quadCastS)
        #expect(MicrophoneModel.identify(name: "HYPERX QUADCAST 2 S USB",
                                        modelName: "", manufacturer: "") == .quadCast2S)
    }

    @Test func excludesOutputVirtualAndDisconnectedDevices() {
        let candidates = [
            candidate(uid: "output", hasInput: false),
            candidate(uid: "virtual", isUSB: false),
            candidate(uid: "offline", isAlive: false),
            candidate(uid: "", name: "HyperX QuadCast S"),
            candidate(uid: "headset", name: "HyperX Cloud III"),
            candidate(uid: "microphone")
        ]
        #expect(MicrophoneCatalog.microphones(in: candidates).map(\.id) == ["microphone"])
    }

    @Test func deduplicatesByUIDWithoutMergingTwoIdenticalModels() {
        let candidates = [candidate(uid: "first"), candidate(uid: "first"), candidate(uid: "second")]
        let microphones = MicrophoneCatalog.microphones(in: candidates)
        #expect(microphones.count == 2)
        #expect(Set(microphones.map(\.id)) == ["first", "second"])
    }

    private func candidate(uid: String, name: String = "HyperX QuadCast S",
                           isUSB: Bool = true, hasInput: Bool = true,
                           isAlive: Bool = true) -> MicrophoneCandidate {
        .init(uid: uid, name: name, modelName: "", manufacturer: "HyperX",
              isUSB: isUSB, hasInput: hasInput, isAlive: isAlive)
    }
}
