//
//  HIDInterfaceDiscovery.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

import Foundation
import IOKit.hid

@MainActor
protocol HIDDiscovering: AnyObject {
    var interfaces: [HIDInterface] { get }
    var state: HIDDiscoveryState { get }
    var onChange: (@MainActor () -> Void)? { get set }
    func start()
    func stop()
    func refresh()
}

@MainActor
final class HIDInterfaceDiscovery: HIDDiscovering {
    private(set) var interfaces: [HIDInterface] = []
    private(set) var state: HIDDiscoveryState = .stopped
    var onChange: (@MainActor () -> Void)?
    private var session: HIDManagerSession?

    func start() {
        guard session == nil else { return }
        do {
            session = try HIDManagerSession(owner: self)
            state = .running
            refresh()
        } catch let HIDTransportError.ioKit(status) {
            stop()
            state = .failed(status)
            onChange?()
        } catch {
            stop()
            state = .failed(kIOReturnError)
            onChange?()
        }
    }

    func stop() {
        session = nil
        interfaces = []
        state = .stopped
        onChange?()
    }

    func refresh() {
        guard let session else { start(); return }
        let previous = interfaces
        let usbDevices = USBRegistry.devices()
        let devices = (IOHIDManagerCopyDevices(session.manager) as? Set<IOHIDDevice>) ?? []
        var currentIDs = Set<UInt64>()
        for device in devices {
            if let info = describe(device, usbDevices: usbDevices) {
                currentIDs.insert(info.id)
                store(info)
            }
        }
        interfaces.removeAll { !currentIDs.contains($0.id) }
        interfaces.sort { $0.id < $1.id }
        if interfaces != previous { onChange?() }
    }

    fileprivate func attached(_ device: IOHIDDevice) {
        guard let info = describe(device, usbDevices: USBRegistry.devices()) else { return }
        store(info)
        interfaces.sort { $0.id < $1.id }
        onChange?()
    }

    fileprivate func removed(_ device: IOHIDDevice) {
        guard let id = USBRegistry.registryID(IOHIDDeviceGetService(device)) else { return }
        remove(id: id)
        onChange?()
    }

    private func store(_ info: HIDInterface) {
        interfaces.removeAll { $0.id == info.id }
        interfaces.append(info)
    }

    private func remove(id: UInt64) {
        interfaces.removeAll { $0.id == id }
    }

    private func describe(_ device: IOHIDDevice, usbDevices: [USBRegistryDevice]) -> HIDInterface? {
        func number(_ key: String) -> Int {
            (IOHIDDeviceGetProperty(device, key as CFString) as? NSNumber)?.intValue ?? 0
        }
        let vendor = number(kIOHIDVendorIDKey), product = number(kIOHIDProductIDKey)
        guard QuadCastSDeviceIDs.contains(vendor: vendor, product: product) else { return nil }
        let service = IOHIDDeviceGetService(device)
        guard service != 0, let id = USBRegistry.registryID(service) else { return nil }
        let usbID = USBRegistry.deviceRegistryID(above: service)
        let identity = usbID.flatMap { USBIdentityResolver.identity(for: $0, devices: usbDevices) }
        return .init(id: id, vendorID: vendor, productID: product,
                     usagePage: number(kIOHIDPrimaryUsagePageKey), usage: number(kIOHIDPrimaryUsageKey),
                     capabilities: .init(inputReportSize: number(kIOHIDMaxInputReportSizeKey),
                                         outputReportSize: number(kIOHIDMaxOutputReportSizeKey),
                                         featureReportSize: number(kIOHIDMaxFeatureReportSizeKey)),
                     usbIdentity: identity)
    }
}

/// Context and manager share a lifetime; callbacks never retain the UI owner.
nonisolated private final class HIDCallbackContext {
    @MainActor weak var owner: HIDInterfaceDiscovery?
    @MainActor init(owner: HIDInterfaceDiscovery) { self.owner = owner }
}

nonisolated private final class HIDManagerSession {
    let manager: IOHIDManager
    private let context: HIDCallbackContext
    private var scheduled = false

    @MainActor init(owner: HIDInterfaceDiscovery) throws {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        context = HIDCallbackContext(owner: owner)
        let filters = QuadCastSDeviceIDs.controllers.map {
            [kIOHIDVendorIDKey: $0.vendor, kIOHIDProductIDKey: $0.product]
        }
        IOHIDManagerSetDeviceMatchingMultiple(manager, filters as CFArray)
        let pointer = Unmanaged.passUnretained(context).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { pointer, result, _, device in
            guard let pointer, result == kIOReturnSuccess else { return }
            // This manager is scheduled exclusively on the main CFRunLoop.
            MainActor.assumeIsolated {
                Unmanaged<HIDCallbackContext>.fromOpaque(pointer).takeUnretainedValue().owner?.attached(device)
            }
        }, pointer)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { pointer, _, _, device in
            guard let pointer else { return }
            MainActor.assumeIsolated {
                Unmanaged<HIDCallbackContext>.fromOpaque(pointer).takeUnretainedValue().owner?.removed(device)
            }
        }, pointer)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        scheduled = true
        let status = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard status == kIOReturnSuccess else { throw HIDTransportError.ioKit(status) }
    }

    deinit {
        IOHIDManagerRegisterDeviceMatchingCallback(manager, nil, nil)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, nil, nil)
        if scheduled {
            IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        }
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }
}
