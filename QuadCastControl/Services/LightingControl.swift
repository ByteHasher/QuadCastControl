import Foundation
import Observation
import IOKit

nonisolated enum LightingFailure: Equatable, Sendable {
    case unavailable, openFailed, unsupported, accessDenied, disconnected, transferFailed
}

nonisolated enum LightingState: Equatable, Sendable {
    case idle, sending, active, stopping
    case failed(LightingFailure)
}

@MainActor
@Observable
final class LightingControl {
    private(set) var states: [String: LightingState] = [:]
    @ObservationIgnored private var tasks: [String: Task<Void, Never>] = [:]
    @ObservationIgnored private var targets: [String: USBDeviceIdentity] = [:]
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
        guard tasks[microphone.id] == nil else { return }
        guard microphone.model == .quadCastS, let identity = microphone.usbIdentity else {
            states[microphone.id] = .failed(.unavailable)
            return
        }
        let id = microphone.id
        let transport = makeTransport(microphone)
        let pause = pause
        targets[id] = identity
        states[id] = .sending
        tasks[id] = Task { [weak self] in
            var failure: LightingFailure?
            do {
                try Task.checkCancellation()
                try await transport.open()
                let reports = QuadCastSColorPacketBuilder.solid(.off)
                while !Task.isCancelled {
                    guard self != nil else { throw CancellationError() }
                    for report in reports {
                        try Task.checkCancellation()
                        try await transport.send(report)
                    }
                    try Task.checkCancellation()
                    if self?.states[id] != .active { self?.states[id] = .active }
                    try await pause()
                }
            } catch {
                if !Task.isCancelled { failure = Self.classify(error) }
            }
            await transport.close()
            self?.tasks[id] = nil
            self?.targets[id] = nil
            self?.states[id] = failure.map(LightingState.failed) ?? .idle
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

    private static func classify(_ error: Error) -> LightingFailure {
        switch error {
        case LightingError.unavailable: return .unavailable
        case LightingError.openFailed: return .openFailed
        case LightingError.unsupportedDescriptor: return .unsupported
        case HIDTransportError.disconnected: return .disconnected
        default:
            let code: Int32
            if case HIDTransportError.ioKit(let status) = error { code = status }
            else { code = Int32(truncatingIfNeeded: (error as NSError).code) }
            switch code {
            case kIOReturnNoDevice, kIOReturnNotAttached: return .disconnected
            case kIOReturnNotPermitted, kIOReturnNotPrivileged, kIOReturnExclusiveAccess: return .accessDenied
            default: return .transferFailed
            }
        }
    }
}
