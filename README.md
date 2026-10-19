# QuadCastControl

Native macOS app for HyperX microphones, built with SwiftUI.

**Work in progress.** Microphone discovery through CoreAudio and QuadCast S
HID discovery/binding are implemented, along with a live-color packet builder
and byte-level tests. QuadCast S supports a solid color picker, color presets,
brightness from 0–100%, and lighting off through a verified USB interface.
Press **Apply color** to start control; subsequent color/brightness edits update
the active stream. Keep the app open to maintain control; stopping it may
restore the microphone's own lighting. Animations and onboard saving are not
implemented yet. Other recognized models
currently have audio discovery only. Physical lighting behavior still needs
validation on each supported revision.

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
