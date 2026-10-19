//
//  Microphone.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

import Foundation

nonisolated enum MicrophoneModel: String, CaseIterable, Sendable {
    case quadCast = "QuadCast"
    case quadCastS = "QuadCast S"
    case quadCast2 = "QuadCast 2"
    case quadCast2S = "QuadCast 2 S"
    case duoCast = "DuoCast"
    case soloCast = "SoloCast"
    case soloCast2 = "SoloCast 2"
    case soloCast2Pro = "SoloCast 2 Pro"
    case flipCast = "FlipCast"

    static func identify(name: String,
                         modelName: String,
                         manufacturer: String) -> Self? {
        func normalized(_ value: String) -> String {
            value.lowercased().filter { $0.isLetter || $0.isNumber }
        }

        let maker = normalized(manufacturer)
        let brandedManufacturer = ["hyperx", "kingston", "hp", "hpinc"].contains(maker)
        for label in [modelName, name] {
            let value = normalized(label)
            let brandedName = value.hasPrefix("hyperx")
            guard brandedName || brandedManufacturer else { continue }
            let product = brandedName ? String(value.dropFirst("hyperx".count)) : value
            for model in allCases {
                let token = normalized(model.rawValue)
                if [token, token + "microphone", token + "usb", token + "usbmicrophone"].contains(product) {
                    return model
                }
            }
        }
        return nil
    }
}

nonisolated struct Microphone: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let model: MicrophoneModel
}

/// Audio metadata only. Identifying a model never authorizes vendor/HID commands.
nonisolated struct MicrophoneCandidate: Sendable {
    let uid: String
    let name: String
    let modelName: String
    let manufacturer: String
    let isUSB: Bool
    let hasInput: Bool
    let isAlive: Bool
}

nonisolated enum MicrophoneCatalog {
    static func microphones(in candidates: [MicrophoneCandidate]) -> [Microphone] {
        var seen = Set<String>()
        return candidates.compactMap { candidate in
            guard candidate.isUSB, candidate.hasInput, candidate.isAlive,
                  !candidate.uid.isEmpty,
                  let model = MicrophoneModel.identify(name: candidate.name,
                    modelName: candidate.modelName, manufacturer: candidate.manufacturer),
                  seen.insert(candidate.uid).inserted else { return nil }
            let name = candidate.name.trimmingCharacters(in: .whitespacesAndNewlines)
            return Microphone(id: candidate.uid,
                              name: name.isEmpty ? "HyperX \(model.rawValue)" : name,
                              model: model)
        }.sorted {
            $0.name == $1.name ? $0.id < $1.id : $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
}
