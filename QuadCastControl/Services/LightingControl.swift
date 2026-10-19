//
//  LightingControl.swift
//  QuadCastControl
//
//  Created by ByteHasher on 19.10.2026.
//

import Foundation
import Observation
import IOKit

nonisolated enum LightingState: Equatable, Sendable {
    case idle, sending, active, stopping
    case failed(LightingFailure)
}

@MainActor
@Observable
final class LightingControl {
    private(set) var states: [String: LightingState] = [:]
    private(set) var activeColors: [String: RGBColor] = [:]
    @ObservationIgnored private var tasks: [String: Task<Void, Never>] = [:]
    @ObservationIgnored private var targets: [String: USBDeviceIdentity] = [:]
    @ObservationIgnored private var requestedColors: [String: RGBColor] = [:]
    @ObservationIgnored private let makeTransport: @Sendable (Microphone) -> any HIDTransport
    @ObservationIgnored private let pause: @Sendable () async throws -> Void

    init(makeTransport: @escaping @Sendable (Microphone) -> any HIDTransport = {
        USBQuadCastSTransport(identity: $0.usbIdentity)
    }, pause: @escaping @Sendable () async throws -> Void = {
        // 20 Hz is an application refresh policy, not a measured hardware timing.
        try await Task.sleep(for: .milliseconds(50))
    }) {
        self.makeTransport = makeTransport
        self.pause = pause
    }

    func turnOff(_ microphone: Microphone) {
        apply(microphone, color: .off, brightnessPercent: 100)
    }

    func apply(_ microphone: Microphone, color: RGBColor, brightnessPercent: Int) {
        guard microphone.model == .quadCastS, let identity = microphone.usbIdentity else {
            states[microphone.id] = .failed(.unavailable)
            return
        }
        let id = microphone.id
        guard states[id] != .stopping else { return }
        if tasks[id] != nil {
            guard targets[id] == identity else { stop(id); return }
            requestedColors[id] = color.scaled(byPercent: brightnessPercent)
            return
        }
        let transport = makeTransport(microphone)
        let pause = pause
        targets[id] = identity
        requestedColors[id] = color.scaled(byPercent: brightnessPercent)
        states[id] = .sending
        tasks[id] = Task { [weak self] in
            let failure = await Self.runSession(transport: transport, pause: pause) { [weak self] in
                guard let self else { throw CancellationError() }
                try await self.sendFrame(for: id, transport: transport)
            }
            self?.finishSession(for: id, failure: failure)
        }
    }

    func stop(_ microphoneID: String) {
        guard let task = tasks[microphoneID] else { return }
        states[microphoneID] = .stopping
        task.cancel()
    }

    func stopAll() { for id in Array(tasks.keys) { stop(id) } }

    func reconcile(_ microphones: [Microphone]) {
        for (id, identity) in targets {
            if !microphones.contains(where: { $0.id == id && $0.usbIdentity == identity && $0.model == .quadCastS }) {
                stop(id)
            }
        }
    }

    /// Runs the transport lifecycle without retaining the controller between frames.
    private static func runSession(transport: any HIDTransport,
                                   pause: @Sendable () async throws -> Void,
                                   sendFrame: @MainActor () async throws -> Void) async -> LightingFailure? {
        var failure: LightingFailure?
        do {
            try Task.checkCancellation()
            try await transport.open()
            while !Task.isCancelled {
                try await sendFrame()
                try await pause()
            }
        } catch {
            if !Task.isCancelled { failure = classify(error) }
        }
        await transport.close()
        return failure
    }

    private func sendFrame(for id: String, transport: any HIDTransport) async throws {
        guard let color = requestedColors[id] else { throw CancellationError() }
        // Capture a single color for the whole header/payload transaction.
        // Edits during a transfer take effect on the next complete frame.
        let reports = QuadCastSColorPacketBuilder.solid(color)
        for report in reports {
            try Task.checkCancellation()
            try await transport.send(report)
        }
        try Task.checkCancellation()
        if activeColors[id] != color { activeColors[id] = color }
        if states[id] != .active { states[id] = .active }
    }

    private func finishSession(for id: String, failure: LightingFailure?) {
        tasks[id] = nil
        targets[id] = nil
        requestedColors[id] = nil
        activeColors[id] = nil
        states[id] = failure.map(LightingState.failed) ?? .idle
    }

    private static func classify(_ error: Error) -> LightingFailure {
        switch error {
        case LightingError.unavailable:
            return .unavailable
        case LightingError.openFailed:
            return .openFailed
        case LightingError.unsupportedDescriptor:
            return .unsupported
        case HIDTransportError.disconnected:
            return .disconnected
        default:
            let code: Int32
            if case HIDTransportError.ioKit(let status) = error { code = status }
            else { code = Int32(truncatingIfNeeded: (error as NSError).code) }
            switch code {
            case kIOReturnNoDevice, kIOReturnNotAttached:
                return .disconnected
            case kIOReturnNotPermitted, kIOReturnNotPrivileged, kIOReturnExclusiveAccess:
                return .accessDenied
            default:
                return .transferFailed
            }
        }
    }
}
