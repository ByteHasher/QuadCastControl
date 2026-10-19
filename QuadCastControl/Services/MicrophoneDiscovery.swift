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

    @ObservationIgnored private var observation: AudioDeviceListObservation?
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    @ObservationIgnored private var started = false
    @ObservationIgnored private let scanner: any MicrophoneScanning

    init(scanner: any MicrophoneScanning = CoreAudioMicrophoneScanner()) {
        self.scanner = scanner
    }

    func start() {
        guard !started else { return }
        started = true
        refresh()
    }

    func stop() {
        started = false
        observation = nil
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
    }

    func refresh() {
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
            case .success(let devices): microphones = devices
            case .failure: microphones = []; scanFailed = true
            }
            isScanning = false
            scanTask = nil
        }
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
