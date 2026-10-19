# QuadCast S hardware protocol facts

This notebook records USB identifiers and published wire-format observations.
Publicly reported formats are separate from local hardware observations;
they have not been validated by RGB transfers in QuadCastControl. The current
app implements discovery, a generic transport and a pure live-color packet
builder with byte-level tests. Hardware color transfers are not connected yet.
All byte offsets are zero-based; hexadecimal values use the `0x` prefix.

## USB identifiers

The current QuadCast S controller allowlist matches these identifiers published
in [QuadcastRGB's device table][device-source]:

| Vendor | VID | Controller PID |
| --- | --- | --- |
| Kingston | `0x0951` | `0x171F` |
| HP | `0x03F0` | `0x0F8B`, `0x028C`, `0x048C`, `0x068C` |

A matching VID/PID identifies a controller; it does not establish which reports
an individual interface supports.

A passive local IORegistry inspection on 2026-10-18 found HP controller
`0x03F0:0x028C` and audio device `0x03F0:0x0294` as the only USB children of an
internal `0x214B:0x7250` hub. This observation applies to that revision.
See the [local identity notes](../Design/HIDLayer.md#discovery-and-identity).

## Published live-color format

The original QuadCast S format uses two 64-byte USB HID Feature transfers on
interface 0. The control request fields are reported by
[QuadcastRGB][device-source]:

| Field | Value |
| --- | --- |
| `bmRequestType` | `0x21` |
| `bRequest` | `0x09` (`SET_REPORT`) |
| `wValue` | `0x0300` (Feature, report ID `0x00`) |
| `wIndex` | `0x0000` |
| `wLength` | `0x0040` (64 bytes) |

The header precedes the color payload:

| Header offset | Value | Meaning in the documented transaction |
| --- | --- | --- |
| 0 | `0x04` | Payload marker |
| 1 | `0xF2` | Live-color command |
| 8 | `0x01` | Packet-count field: one following color packet |
| All other bytes | `0x00` | Zero-filled |

The [published transaction][device-source] labels byte 8 as a packet count and
uses `0x01` before each color packet, including successive animation frames.
It does not demonstrate other values. Byte 8 is therefore not documented here
as a total animation-frame count; accepting multiple color packets after one
header remains unverified.

Report ID `0x00` denotes an unnumbered report. The 64-byte USB data payload has
no extra report-ID byte; header byte `0x04` is payload data.

The two-zone solid-color payload is described by QuadcastRGB's
[color layout definitions][color-definitions] and
[color data construction][color-source]:

| Color payload offset | Value |
| --- | --- |
| 0 | `0x81` |
| 1, 2, 3 | Upper-zone red, green, blue |
| 4 | `0x81` |
| 5, 6, 7 | Lower-zone red, green, blue |
| 8–63 | `0x00` |

Each color channel is one unsigned byte (`0–255`), in RGB order. A solid color
across both zones uses equal RGB triples. This describes a live-color payload,
not an onboard-save command. Interface descriptors and report availability
must be checked per revision; the controller ID alone is insufficient.

## Timing measurements

| Measurement | Status |
| --- | --- |
| Header-to-color delay | to be measured |
| Frame refresh interval | to be measured |
| Device response latency and transfer timeout | to be measured |
| Required repeat behavior and behavior after disconnect/exit | to be measured |

No numeric timing from a reference implementation is treated as a measured
hardware requirement here.

## Research sources

- [QuadcastRGB — device IDs, Feature request fields and header][device-source],
  commit `e15a81c98221a4ff3fbc86e24597ab2f47c1a388`.
- QuadcastRGB — [color definitions][color-definitions] and
  [color payloads][color-source],
  commit `e15a81c98221a4ff3fbc86e24597ab2f47c1a388`.
- [OpenHyperX](https://github.com/chase-irql/OpenHyperX), protocol research
  reference, commit `0ff65425bbe18218fe6024ad048dea4a96d83bc9`.
- [OpenRGB device investigation](https://gitlab.com/CalcProgrammer1/OpenRGB/-/issues/1298),
  USB descriptors and controller/audio separation.
- [Apple TN3190](https://developer.apple.com/documentation/technotes/tn3190-usb-audio-device-design-considerations),
  USB Audio device identity.

The links identify research sources. This document contains protocol facts,
not source-code excerpts, reference algorithms, retry policies or error handling.

[device-source]: https://github.com/Ors1mer/QuadcastRGB/blob/e15a81c98221a4ff3fbc86e24597ab2f47c1a388/modules/devio.c
[color-definitions]: https://github.com/Ors1mer/QuadcastRGB/blob/e15a81c98221a4ff3fbc86e24597ab2f47c1a388/modules/rgbmodes.h
[color-source]: https://github.com/Ors1mer/QuadcastRGB/blob/e15a81c98221a4ff3fbc86e24597ab2f47c1a388/modules/rgbmodes.c
