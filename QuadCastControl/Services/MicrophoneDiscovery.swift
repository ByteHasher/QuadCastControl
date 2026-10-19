//
//  MicrophoneDiscovery.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class MicrophoneDiscovery {
    private(set) var microphones: [Microphone] = []
    private(set) var isScanning = false
    private(set) var scanFailed = false
    private(set) var automaticUpdatesAvailable = true
    private(set) var hidState: HIDDiscoveryState = .stopped

    @ObservationIgnored private var observation: AudioDeviceListObservation?
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    @ObservationIgnored private var started = false
    @ObservationIgnored private let scanner: any MicrophoneScanning
    @ObservationIgnored private let hid: any HIDDiscovering

    init(scanner: any MicrophoneScanning = CoreAudioMicrophoneScanner(),
         hid: (any HIDDiscovering)? = nil) {
        self.scanner = scanner
        self.hid = hid ?? HIDInterfaceDiscovery()
    }

    func start() {
        guard !started else { return }
        started = true
        hid.onChange = { [weak self] in self?.updateHIDBindings() }
        hid.start()
        refresh()
    }

    func stop() {
        started = false
        hid.onChange = nil
        hid.stop()
        hidState = .stopped
        microphones = MicrophoneHIDBinder.bind(microphones, interfaces: [])
        observation = nil
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
    }

    func refresh() {
        if started { hid.refresh(); hidState = hid.state }
        if started && observation == nil { installObservation() }
        scanTask?.cancel()
        isScanning = true
        scanFailed = false
        // CoreAudio property access can wait on a driver; keep it off the UI actor.
        scanTask = Task { [weak self, scanner] in
            let result = await Task.detached(priority: .utility) {
                Result { try scanner.scan() }
            }.value
            // Discard an older snapshot if unplugging triggered a newer scan or the window closed.
            guard !Task.isCancelled, let self else { return }
            switch result {
            case .success(let devices):
                if started { hid.refresh() }
                microphones = MicrophoneHIDBinder.bind(devices, interfaces: hid.interfaces)
                hidState = hid.state
            case .failure: microphones = []; scanFailed = true
            }
            isScanning = false
            scanTask = nil
        }
    }

    func transport(for interfaceID: UInt64, microphoneID: String) -> (any HIDTransport)? {
        guard microphones.contains(where: {
            $0.id == microphoneID && $0.hidInterfaces.contains(where: { $0.id == interfaceID })
        }) else { return nil }
        return hid.transport(for: interfaceID)
    }

    private func updateHIDBindings() {
        hidState = hid.state
        microphones = MicrophoneHIDBinder.bind(microphones, interfaces: hid.interfaces)
    }

    private func installObservation() {
        do {
            observation = try AudioDeviceListObservation { [weak self] _, _ in
                Task { @MainActor [weak self] in
                    guard let self, started else { return }
                    refresh()
                }
            }
            automaticUpdatesAvailable = true
        } catch {
            automaticUpdatesAvailable = false
        }
    }
}
