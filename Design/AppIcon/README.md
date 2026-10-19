# Application icon

The editable source is `QuadCastControl/AppIcon.icon`. Open this document in
Apple Icon Composer, included with Xcode. The SVG artwork was drawn specifically
for this project; it contains no HyperX or NGENUITY logos or artwork.

The icon has three visual planes on a 1024 × 1024 canvas:

1. A dark navy background, defined by the document's fill.
2. The microphone body, suspension and stand in `Assets/02-Microphone.svg`.
3. The violet, pink and blue grille in `Assets/03-Grille.svg`.

Icon Composer stores the foreground group first. Keep the grille above the body.
The source SVGs remain editable; reflections, material edges and shadows are
provided by Icon Composer rather than baked into the artwork.

The app icon build setting is `AppIcon`. Xcode compiles the `.icon` document for
Liquid Glass appearances and also generates the flattened `.icns` fallback for
the macOS 15 deployment target. No runtime availability check is needed for icon
assets.

`Preview.png`, `Preview-Dark.png` and `Preview-32.png` are native Icon Composer
renders for visual review. They are outside the app's source folder and are not
bundled as application resources. After editing the source, regenerate previews
with Icon Composer's export command.
