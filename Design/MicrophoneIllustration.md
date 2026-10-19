# Procedural microphone illustration

`Views/MicrophoneIllustration.swift` draws a front-facing condenser microphone
using SwiftUI Canvas paths, shading and geometric construction. The design has
a tall cylindrical body, hexagonal grille, two suspension rings, metallic braces,
neutral gain markers and a tabletop stand. It contains no wordmark or lettering.
No raster microphone asset, traced bitmap or generated image is loaded.

The mesh is generated from six-vertex cells; a sine projection compresses their
spacing at the cylinder's edges. Gradients describe dark metal and the mounting
hardware. Surface lines, screws and control markers are procedural geometry.
The artwork was written in Swift for this project, rather than converted from
or sampled from the former product image. The removed image is not used at
runtime or stored in the app asset catalog.

The public view takes RGBColor, brightness and an enabled flag. Brightness uses
RGBColor.scaled(byPercent:), matching the controller's clamping and rounding.
Only the grille is illuminated; the enclosure remains dark metal. Off uses a
dim neutral grille without emission. Zero brightness and black produce no glow.

The Canvas renderer exposes the RGB channels and emission as animatable data,
so its geometry retains the same shape as colors interpolate over 0.25 seconds.
macOS Reduce Motion disables interpolation. MicrophoneStage retains the existing
layout. Other microphone models retain a generic, unlit symbol rather than an
inaccurate QuadCast S silhouette. The drawing visualizes the selected color;
it is not device readback or a calibrated model of the physical LEDs.
