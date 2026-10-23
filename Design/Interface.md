# Console interface

The workspace follows the user's previous design: a theme-aware sidebar and
header, device tabs, microphone stage and a four-column lighting console. The
app wordmark is **QUADCAST CONTROL**. The microphone is a procedural SwiftUI illustration with a colored grille;
see [MicrophoneIllustration.md](MicrophoneIllustration.md).

The sidebar supports collapse, microphone selection, diagnostics and settings.
Its collapse/expand button lives in the sidebar's existing top inset: at the
top right when expanded, and centered above the brand icon when collapsed.
Moving the button adds no header row or vertical offset to the wordmark.
Collapsed brand and navigation rows fill the rail width and center their icons;
text spacing and trailing spacers are present only when expanded, so they cannot
shift the icon column away from the centered hamburger button.
Its gradient follows the light or dark palette of the main panels. Selection uses a muted
cyan fill and the shared accent color for its icon and leading indicator.
Overview and diagnostics display actual discovery metadata. Audio explains the
current support boundary and opens macOS System Settings; it does not invent
unimplemented audio controls. The profile popover summarizes the current draft.

The app has a single workspace window (`Window`, not `WindowGroup`), so there is
no File › New Window. `QuadCastControlApp` owns the one `MicrophoneDiscovery` and
`LightingControl` and injects them through the environment; a microphone never
receives two concurrent color streams. Closing the window still stops discovery
and lighting; reopening it starts discovery again with the same controllers.

`ContentView` owns a draft per microphone for the current session, so navigating
between tabs does not reset the editor. The lighting scene previews that draft;
it is not a readback of the hardware. Color, hue/saturation, byte-valued presets,
brightness, off and stop use the existing `LightingControl`. User edits apply
immediately while Lighting is on; there is no Apply button or preview-only mode.
Saturation is labeled separately from the brightness control.
Opening the workspace, changing tabs and selecting a microphone do not start
color transfers. Choosing even the already-selected preset, editing a color,
changing brightness or switching Lighting on starts control. Switching Lighting
off sends black while keeping the chosen color. Edits while off change only the
selection until Lighting is switched on. Stop closes the transport; the next edit
while enabled or an explicit toggle can start it again. A failure or reconnection
does not retry on its own. The sidebar has one selectable row per device,
including in its collapsed state, rather than a duplicate Microphone category.

The default window is 1240 × 820 with a 1024 × 680 minimum. The stage follows the
available viewport height. The lighting console and footer stay visible even
at the minimum window size; only the microphone preview shrinks.
The workspace relies on the native hidden-titlebar safe area for the window
buttons; it adds no extra top spacer beneath that area.
Columns share the available width, while the sidebar can collapse to an icon rail.
English/Russian labels remain in String Catalog. Settings offers System (the
default), English and Russian. AppLanguageView observes the saved AppStorage
choice and updates the locale without recreating the workspace or its device
sessions. System chooses the best supported language from macOS's preferred
languages, falling back to English. Model-provided LocalizedStringResource
values also receive the selected locale, including titles, help, accessibility
labels and error messages. UI uses macOS 15-compatible APIs.

The lighting page is a non-scrolling vertical layout. SwiftUI reserves the
console's full 320 pt height and the footer's actual localized text height first.
The flexible stage receives the remaining space, without a minimum fraction or
fixed minimum height that can push the controls below the window. All columns
share one console-height value, including room for saturation and the hex field.
Overview remains scrollable and uses 58% of its viewport for the preview.
Within either stage, the illustration fits both the height minus a 30 pt margin
and a central slot covering 44% of the stage width. Its 320:540 aspect ratio is
preserved, including with the sidebar collapsed. Wide, short windows are limited
by height; narrow, tall windows by width.
The control status shows a green dot and “Live on microphone” after the desired
color pair is sent, or neutral “Off” after black is sent with power disabled.
Pending transfers and errors remain explicit. Before the first send, or after
stopping, “Not applied” avoids claiming hardware control from the draft alone.
The power icon reflects the editor's enabled flag, which defaults to on, rather
than whether a USB session has started. It agrees with the illustration before
the first write; the first press sends black instead of starting the default
color. This is the selected lighting state, not hardware readback. The separate
status still reports pending commands, confirmed sends, stopped control or errors.
Startup and discovery do not send commands or overwrite the microphone's color.
The caption is the single-line “Changes apply instantly”.

## Appearance

Settings provides System (the default), Light and Dark modes. The app and the
settings picker share AppAppearance.storageKey through AppStorage. The window's
AppAppearanceView observes it and updates the SwiftUI color scheme as well as the
native preferred appearance, so selection persists between launches and updates
the open window immediately. System passes
nil to preferredColorScheme and follows macOS appearance changes. Choosing a
mode changes presentation only; it does not recreate discovery or lighting
controllers, reset the editor, or send a command to the microphone.

WorkspaceTheme uses asset-catalog colors with light and dark variants for the main surfaces,
sidebar, labels, separators, accents and status colors. The hue marker and white
preset keep a visible outline in both modes. The selected effect retains white
text on its blue background. The microphone's dark physical materials and RGB
values remain independent of the app's appearance.
