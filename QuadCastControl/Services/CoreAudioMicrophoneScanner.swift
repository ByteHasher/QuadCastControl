//
//  CoreAudioMicrophoneScanner.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

import CoreAudio
import Foundation

nonisolated enum MicrophoneScanError: Error, Equatable {
    case coreAudio(OSStatus)
    case unexpectedPropertySize
}

/// Abstraction over device scanning so `MicrophoneDiscovery` can be tested with a fake.
nonisolated protocol MicrophoneScanning: Sendable {
    func scan() throws -> [Microphone]
}

/// Reads device properties only; never starts a stream or opens the microphone for recording.
nonisolated struct CoreAudioMicrophoneScanner: MicrophoneScanning {
    init() {}

    func scan() throws -> [Microphone] {
        let candidates = try Self.deviceIDs().compactMap(Self.candidate(for:))
        let usbDevices = USBRegistry.devices()
        return MicrophoneCatalog.microphones(in: candidates).map { microphone in
            var result = microphone
            result.usbIdentity = USBIdentityResolver.audioIdentity(uid: microphone.id, devices: usbDevices)
            return result
        }
    }

    // MARK: - Device list

    private static func deviceIDs() throws -> [AudioDeviceID] {
        let system = AudioObjectID(kAudioObjectSystemObject)
        var address = AudioObjectPropertyAddress.hardwareDevices
        var size: UInt32 = 0
        try check(AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size))

        let stride = MemoryLayout<AudioDeviceID>.stride
        guard size > 0 else { return [] }
        guard Int(size) % stride == 0 else { throw MicrophoneScanError.unexpectedPropertySize }

        var ids = [AudioDeviceID](repeating: 0, count: Int(size) / stride)
        let allocatedSize = size
        try ids.withUnsafeMutableBytes { buffer in
            guard let base = buffer.baseAddress else { throw MicrophoneScanError.unexpectedPropertySize }
            try check(AudioObjectGetPropertyData(system, &address, 0, nil, &size, base))
        }
        // The list can shrink between the two calls if a device is unplugged in between.
        guard size <= allocatedSize, Int(size) % stride == 0 else {
            throw MicrophoneScanError.unexpectedPropertySize
        }
        return Array(ids.prefix(Int(size) / stride))
    }

    // MARK: - Candidate

    /// Collects raw facts about a device; `MicrophoneCatalog` decides whether it is a supported microphone.
    private static func candidate(for id: AudioDeviceID) -> MicrophoneCandidate? {
        // Without a stable UID the device cannot be tracked across reconnects.
        guard let uid = string(id, kAudioDevicePropertyDeviceUID) else { return nil }
        return MicrophoneCandidate(
            uid: uid,
            name: string(id, kAudioObjectPropertyName) ?? "",
            modelName: string(id, kAudioObjectPropertyModelName) ?? "",
            manufacturer: string(id, kAudioObjectPropertyManufacturer) ?? "",
            isUSB: scalar(id, kAudioDevicePropertyTransportType) == kAudioDeviceTransportTypeUSB,
            hasInput: hasInputStreams(id),
            isAlive: scalar(id, kAudioDevicePropertyDeviceIsAlive) == 1)
    }

    // MARK: - Property readers

    private static func scalar(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector) -> UInt32? {
        var address = AudioObjectPropertyAddress(selector)
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &value) == noErr,
              size == MemoryLayout<UInt32>.size else { return nil }
        return value
    }

    private static func string(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String? {
        var address = AudioObjectPropertyAddress(selector)
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &value) == noErr else { return nil }
        // CoreAudio string properties follow the Create rule: the caller owns the reference.
        return value?.takeRetainedValue() as String?
    }

    private static func hasInputStreams(_ id: AudioObjectID) -> Bool {
        var address = AudioObjectPropertyAddress(kAudioDevicePropertyStreams,
                                                 scope: kAudioDevicePropertyScopeInput)
        var size: UInt32 = 0
        return AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size) == noErr
            && size >= MemoryLayout<AudioStreamID>.size
    }

    private static func check(_ status: OSStatus) throws {
        guard status == noErr else { throw MicrophoneScanError.coreAudio(status) }
    }
}

// MARK: - Device list observation

/// Subscription token: the listener stays registered exactly as long as this object lives.
nonisolated final class AudioDeviceListObservation {
    private let listener: AudioObjectPropertyListenerBlock
    private var isRegistered = false

    init(listener: @escaping AudioObjectPropertyListenerBlock) throws {
        // CoreAudio removes a listener only by the identical block, so keep a reference to it.
        self.listener = listener
        var address = AudioObjectPropertyAddress.hardwareDevices
        let status = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &address, .main, listener)
        guard status == noErr else { throw MicrophoneScanError.coreAudio(status) }
        isRegistered = true
    }

    deinit {
        // A class whose init throws after full initialization still runs deinit;
        // don't try to remove a listener that was never added.
        guard isRegistered else { return }
        var address = AudioObjectPropertyAddress.hardwareDevices
        AudioObjectRemovePropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &address, .main, listener)
    }
}

// MARK: - Property address helpers

nonisolated extension AudioObjectPropertyAddress {
    init(_ selector: AudioObjectPropertySelector,
         scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) {
        self.init(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }

    /// The system-wide list of audio devices; shared by the scanner and the observation.
    static var hardwareDevices: Self { Self(kAudioHardwarePropertyDevices) }
}
