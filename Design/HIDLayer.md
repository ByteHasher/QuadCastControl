# HID layer

The microphone list still comes exclusively from CoreAudio. HID interfaces are
attachments to these records; they never create another microphone row.

## Source layout

- `QuadCastControl/HID/`: HID interface metadata, discovery and the transport
  protocol.
- `QuadCastControl/USB/`: USB product/device identity, registry access and the
  USB-backed QuadCast S transport.
- `QuadCastControl/Devices/QuadCastS/`: model-specific device IDs, audio/HID
  binding, lighting target validation and the color packet builder.
- `QuadCastControlTests/Support/`: mock transport, operation log and test fixtures.

The folders organize one application module; no protocol behavior or target
membership is changed. Xcode's synchronized groups include the relocated files.

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
audio, or start RGB. Discovery retains interface metadata, not per-device
transport objects. It unregisters callbacks and clears metadata on stop, and
removes interface records when devices disappear. The lighting USB transport
is opened only by an explicit user action.

## Transport

`HIDTransport` is the async contract shared by lighting control and its mock.
Numbered report buffers include one report ID byte; unnumbered buffers include
payload only. Discovery does not create or expose transports.

`USBQuadCastSTransport` is the only native transport and is the default used by
`LightingControl` for all current color/off writes. It sends HID Feature
`SET_REPORT` control transfers through
IOUSBHost on the verified QuadCast S interface 0. This path is needed because
macOS can expose only the separate consumer-control HID collection through
IOHIDManager, leaving the RGB interface unavailable there. It accepts only
64-byte unnumbered Feature writes; status reads are unsupported.
See [LightingControl.md](LightingControl.md) for descriptor gating and USB access.

`MockHIDTransport` lives in `QuadCastControlTests/Support/MockHIDTransport.swift`
and is compiled only into the unit-test target, together with its operation log,
mock capabilities and mock-specific errors. It is an actor with queued Feature responses,
explicit disconnect and one-shot error injection. Framing/capability validation
used only by the mock also lives in the test target. The mock does not emulate
IOUSBHost permissions or native descriptor validation. Tests can exercise it
without IOHIDManager or real hardware.
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
