# Solid-color lighting control

`LightingControl` starts after a user color/brightness edit while **Lighting**
is on, or an explicit change of the **Lighting** switch. There is no Apply step. It opens a `HIDTransport`, sends the existing builder's
header and color packet, and refreshes complete pairs while the window remains open. It has no
startup restore, flash-save operation, device-status request or automatic retry.
Construction and microphone discovery do not start lighting writes.

The editor provides an sRGB color picker, eight presets and a 0–100% brightness
slider. Brightness uses `RGBColor.scaled(byPercent:)` before packet construction.
`Models/ColorPreset.swift` stores each preset as exact `UInt8` RGB values and
exposes literal `LocalizedStringResource` keys for String Catalog extraction.
The editor stores `RGBColor`; only the native picker's custom input needs a
SwiftUI-to-sRGB byte conversion. That bridge lives in `Views/RGBColor+SwiftUI.swift`.
Preset selection assigns the model color directly, without a floating-point
round trip. Error messages are provided by the `LightingFailure` extension.
During control, edits replace the requested color for the next frame on
the same open transport. Each frame captures one color before sending its header,
so an edit cannot mix values inside a transaction. Intermediate picker/slider
events are coalesced by the existing refresh loop, not queued as USB requests.

Switching **Lighting** off replaces the requested color with black on that same
stream. The editor preserves its selected color and brightness; edits while
switched off stay as a selection until **Lighting** is switched on. UI writes
originate in user-action bindings, not view appearance or draft observation;
navigation, stopping, failures and reconnection do not automatically start writes.
The next user edit while enabled, or an explicit toggle, starts control again.
Selecting the already-selected preset also starts control. Settings are not persisted yet.

`USBQuadCastSTransport` reaches the RGB interface even when IOHIDManager exposes
only the separate consumer-control HID collection. It uses the audio record's
USB identity and the verified enclosure relationship to find exactly one
allowlisted controller. It opens only HID-class interface 0 with no capture or
seize options. It checks the interface descriptor and reads the standard HID
report descriptor; an exact match to the format in `Docs/PROTOCOL.md` is required
before any Feature write. It rejects numbered, non-Feature and non-64-byte
reports. Audio interfaces, firmware commands and persistent storage are not used.

The app keeps App Sandbox and USB access enabled. IOUSBHost also needs the
`com.apple.security.temporary-exception.iokit-user-client-class` entitlement
with the single class `AppleUSBHostFrameworkInterfaceClient`. A local system log
confirmed that USB access alone denied this client before any color transfer.
This is Apple's [documented IOKit user-client exception](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/AppSandboxTemporaryExceptionEntitlements.html);
Mac App Store distribution would require explaining the temporary entitlement
to App Review. No capture entitlement or sandbox disablement is used.

On 2026-10-19, a separate signed, sandboxed read-only probe with these
entitlements successfully opened local controller `03F0:028C` interface 0 and
read its 31-byte report descriptor. No color command was sent by that probe.

The native calls execute on a transport actor, off the UI actor. The 50 ms
refresh pause and 2 s transfer timeout are application policies, not measured
device requirements. The UI reports active color/off control after a complete
pair succeeds; it does not claim to read back the actual LEDs. Physical output,
required cadence and behavior after closing the app still need hardware checks.

**Stop lighting control**, window closure, lost identity or unplugging cancel
the task and close the transport. An in-flight synchronous USB request may finish
before cancellation takes effect, bounded by the transfer timeout. Stopping
sends no additional lighting command and may allow firmware lighting to resume.
Reconnection does not restart writes; a user edit or toggle is required.

English/Russian UI strings live in `Localizable.xcstrings`. Errors distinguish
missing identity, unsupported descriptor, access/busy failure, disconnection and
transfer failure. A native interface-open failure has its own message and logs
the native error domain/code, rather than being reported as a failed color send.
A failed header prevents its color packet from being sent.

Tests inject `MockHIDTransport` and a controllable pause: no native USB open or
hardware write is performed by the test suite. Target resolution and exact
descriptor validation are tested separately using synthetic metadata.
