# Lighting-off control

`LightingControl` starts only after the user presses **Turn off lighting**.
It opens a `HIDTransport`, sends the existing builder's header and black color
packet, and refreshes complete pairs while the window remains open. It has no
startup restore, flash-save operation, device-status request or automatic retry.
Construction and microphone discovery do not start lighting writes.

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
device requirements. The UI reports active lighting-off control after a complete
pair succeeds; it does not claim to read back the actual LEDs. Physical output,
required cadence and behavior after closing the app still need hardware checks.

**Stop lighting control**, window closure, lost identity or unplugging cancel
the task and close the transport. An in-flight synchronous USB request may finish
before cancellation takes effect, bounded by the transfer timeout. Stopping
sends no additional lighting command and may allow firmware lighting to resume.
Reconnection does not restart writes; the user must press the button again.

English/Russian UI strings live in `Localizable.xcstrings`. Errors distinguish
missing identity, unsupported descriptor, access/busy failure, disconnection and
transfer failure. A native interface-open failure has its own message and logs
the native error domain/code, rather than being reported as a failed color send.
A failed header prevents its color packet from being sent.

Tests inject `MockHIDTransport` and a controllable pause: no native USB open or
hardware write is performed by the test suite. Target resolution and exact
descriptor validation are tested separately using synthetic metadata.
