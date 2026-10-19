# QuadCastControl

Native macOS app for HyperX microphones, built with SwiftUI.

**Work in progress.** Microphone discovery through CoreAudio and QuadCast S
HID discovery/binding are implemented, along with a live-color packet builder
and byte-level tests. RGB controls, hardware color transfers and onboard saving
are not implemented yet. Other recognized models currently have audio discovery only.

**Unofficial, not affiliated with HyperX/HP.**

## Build and run

Requires macOS 15 or later and Xcode 26 or later.

1. Open `QuadCastControl.xcodeproj` in Xcode.
2. Select the `QuadCastControl` scheme and your Mac.
3. Choose your signing team if needed, then Run.

App Sandbox USB access is enabled in the app's entitlements.

## Documentation

- [Hardware protocol facts and research sources](Docs/PROTOCOL.md)
- [HID layer and mock transport](Design/HIDLayer.md)
- [Microphone discovery](Design/MicrophoneDiscovery.md)

## License

[MIT](LICENSE) — Copyright (c) 2026 ByteHasher.
