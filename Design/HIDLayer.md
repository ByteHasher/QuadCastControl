# HID layer

The microphone list still comes exclusively from CoreAudio. HID interfaces are
attachments to these records; they never create another microphone row.

## Discovery and identity

`HIDInterfaceDiscovery` uses `IOHIDManager` with explicit QuadCast S controller
VID/PID pairs from `QuadCastSDeviceIDs`. It handles arrival/removal and exposes
report-size capabilities separately from microphone identification. A discovered
HID interface does not imply that RGB Feature reports are available on it.

`USBIdentityResolver` matches Apple's documented USB Audio UID against USB
descriptor manufacturer/product and the exact serial number or hexadecimal
location ID. See [Apple TN3190](https://developer.apple.com/documentation/technotes/tn3190-usb-audio-device-design-considerations).
Missing or ambiguous identities are left unlinked. No name-only, list-position,
global single-device or arbitrary shared-hub fallback is used.

Audio and HID may share one USB device. The HP QuadCast S 03F0:028C controller
and 03F0:0294 audio function are instead separate devices. A passive IORegistry
inspection on this revision confirmed both as the only USB children of the
internal 214B:7250 hub. That narrowly scoped enclosure rule links them without
confusing two microphones attached through an external hub. Other split-device
revisions require their own verified topology before they can be auto-linked.

Discovery reads properties and opens IOHIDManager with shared access. It does
not send Feature/Output reports, query vendor status, seize devices, record
audio, or start RGB. The native transport is opened only by an explicit client
call. The discovery/session objects unregister callbacks and invalidate retained
transports on stop or removal.

## Transport

`HIDTransport` provides async open/close, report sending and Feature reads.
`IOHIDTransport` serializes native operations in an actor. Lengths are bounded
by the device's reported capabilities and an allocation limit. Numbered buffers
include one report ID byte; unnumbered buffers include payload only.

`MockHIDTransport` is an actor with an operation log, queued Feature responses,
explicit disconnect and one-shot error injection. Its validation matches the
native adapter. Tests can exercise it without IOHIDManager or real hardware.
`MicrophoneDiscovery` also accepts an injected `HIDDiscovering` provider.

## Sandbox and validation

Both app configurations use `QuadCastControl/QuadCastControl.entitlements` with
`com.apple.security.device.usb = true` and App Sandbox enabled. This corresponds
to **Signing & Capabilities → App Sandbox → Hardware → USB**. Other system access
restrictions may still apply; an open failure is reported separately from the
audio connection. See [Apple's USB entitlement documentation](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.device.usb).

The HID binding/transport tests use synthetic metadata and mock reports. Local
signed builds are checked for the actual USB entitlement. Vendor commands and
real Feature/Output transfers are intentionally not part of the discovery tests.
Explicit user-triggered lighting control is documented separately in
[LightingControl.md](LightingControl.md).
