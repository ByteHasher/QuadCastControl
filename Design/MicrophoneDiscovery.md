# USB microphone discovery

This first stage discovers audio inputs. It does not implement microphone
settings, RGB, mute state or vendor USB/HID commands.

- `CoreAudioMicrophoneScanner` reads the system device list, USB transport,
  liveness, input streams, name, model name, manufacturer and stable device UID.
  It never starts an audio stream, records samples or changes the default input.
- `MicrophoneCatalog` recognizes HyperX microphone model names and rejects
  output-only endpoints, virtual devices and disconnected records. A repeated
  UID is collapsed; different UIDs remain separate even for identical models.
  Recognition is for display only and must not authorize future vendor commands.
- `MicrophoneDiscovery` listens for CoreAudio device-list changes, scans off the
  UI actor and discards superseded results. Closing the view unregisters the
  listener and cancels pending UI updates. Manual Refresh also retries listener
  registration after a failure.
- The interface strings live in `Resources/Localizable.xcstrings`. English and
  Russian follow the user's system language.

The model/catalog tests use synthetic metadata. Physical connection, unplugging
and reconnecting still need to be checked on the user's Mac. Detection uses the
audio input, so a microphone's separate lighting/HID controller is not displayed
as another microphone.

The next stage attaches HID metadata and a transport to these audio records;
see [HIDLayer.md](HIDLayer.md) for identity rules, sandbox configuration and tests.
