//
//  MicrophoneIllustration.swift
//  QuadCastControl
//
//  Created by ByteHasher on 19.10.2026.
//

import SwiftUI

/// Procedural product illustration: paths, metallic shading and a cylindrical
/// hexagonal grille. No product photograph, traced bitmap or logo is used.
struct MicrophoneIllustration: View {
    let color: RGBColor
    var brightnessPercent = 100
    var isEnabled = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var output: RGBColor {
        isEnabled ? color.scaled(byPercent: brightnessPercent) : RGBColor(red: 22, green: 23, blue: 26)
    }

    var body: some View {
        MicrophoneDrawing(red: Double(output.red) / 255, green: Double(output.green) / 255,
                          blue: Double(output.blue) / 255,
                          emission: isEnabled && output != .off ? 1 : 0)
            .aspectRatio(320.0 / 540, contentMode: .fit)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: color)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: brightnessPercent)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: isEnabled)
            .accessibilityHidden(true)
    }
}

private struct MicrophoneDrawing: View, Animatable {
    var red: Double
    var green: Double
    var blue: Double
    var emission: Double

    // Canvas drawing commands do not interpolate their own parameters. Expose
    // the channels explicitly so the grille and its glow animate together.
    var animatableData: AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<Double, Double>> {
        get { .init(.init(red, green), .init(blue, emission)) }
        set {
            red = newValue.first.first; green = newValue.first.second
            blue = newValue.second.first; emission = newValue.second.second
        }
    }

    private var light: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: 1) }

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 320, size.height / 540)
            context.translateBy(x: (size.width - 320 * scale) / 2, y: (size.height - 540 * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            drawStand(in: &context)
            drawRearSuspension(in: &context)
            drawCapsule(in: &context)
            drawGrille(in: &context)
            drawFrontSuspension(in: &context)
            drawControls(in: &context)
        }
    }

    private func drawStand(in context: inout GraphicsContext) {
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 5))
            layer.fill(Path(ellipseIn: CGRect(x: 48, y: 515, width: 224, height: 14)), with: .color(.black.opacity(0.35)))
        }
        let stem = Path(roundedRect: CGRect(x: 145, y: 446, width: 30, height: 64), cornerRadius: 4)
        context.fill(stem, with: metal(from: 145, to: 175))
        for x in stride(from: 149.0, through: 172, by: 4) {
            line(CGPoint(x: x, y: 457), CGPoint(x: x, y: 499), color: .black.opacity(0.5), width: 0.8, in: &context)
        }
        var base = Path()
        base.move(to: CGPoint(x: 52, y: 507))
        base.addCurve(to: CGPoint(x: 268, y: 507), control1: CGPoint(x: 78, y: 499), control2: CGPoint(x: 242, y: 499))
        base.addLine(to: CGPoint(x: 268, y: 518))
        base.addCurve(to: CGPoint(x: 52, y: 518), control1: CGPoint(x: 251, y: 535), control2: CGPoint(x: 69, y: 535))
        base.closeSubpath()
        context.fill(base, with: metal(from: 52, to: 268))
        context.fill(Path(ellipseIn: CGRect(x: 52, y: 497, width: 216, height: 23)),
                     with: .linearGradient(Gradient(colors: [Color(white: 0.16), Color(white: 0.065)]),
                                           startPoint: CGPoint(x: 160, y: 497), endPoint: CGPoint(x: 160, y: 520)))
        context.stroke(Path(ellipseIn: CGRect(x: 52, y: 497, width: 216, height: 23)),
                       with: .color(.white.opacity(0.09)), lineWidth: 0.6)
        context.fill(Path(ellipseIn: CGRect(x: 141, y: 495, width: 38, height: 7)), with: .color(.black.opacity(0.4)))
    }

    private func drawRearSuspension(in context: inout GraphicsContext) {
        for x in [88.0, 228] {
            let rod = Path(roundedRect: CGRect(x: x, y: 297, width: 4, height: 48), cornerRadius: 2)
            context.fill(rod, with: metal(from: x, to: x + 4))
        }
        for points in [
            [CGPoint(x: 112, y: 258), CGPoint(x: 108, y: 276), CGPoint(x: 67, y: 296)],
            [CGPoint(x: 208, y: 258), CGPoint(x: 212, y: 276), CGPoint(x: 253, y: 296)],
            [CGPoint(x: 67, y: 346), CGPoint(x: 108, y: 369), CGPoint(x: 112, y: 381)],
            [CGPoint(x: 253, y: 346), CGPoint(x: 212, y: 369), CGPoint(x: 208, y: 381)]
        ] {
            var path = Path()
            path.addLines(points)
            context.stroke(path, with: .color(Color(white: 0.06)), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            context.stroke(path, with: .linearGradient(Gradient(colors: [Color(white: 0.62), Color(white: 0.25), Color(white: 0.6)]),
                                                      startPoint: points[0], endPoint: points[2]),
                           style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
        }
    }

    private func drawCapsule(in context: inout GraphicsContext) {
        var body = Path()
        body.move(to: CGPoint(x: 103, y: 47))
        body.addCurve(to: CGPoint(x: 217, y: 47), control1: CGPoint(x: 103, y: 7), control2: CGPoint(x: 217, y: 7))
        body.addLine(to: CGPoint(x: 217, y: 435))
        body.addCurve(to: CGPoint(x: 103, y: 435), control1: CGPoint(x: 217, y: 466), control2: CGPoint(x: 103, y: 466))
        body.closeSubpath()
        context.fill(body, with: metal(from: 103, to: 217))
        context.stroke(body, with: .color(.white.opacity(0.10)), lineWidth: 0.7)

        context.drawLayer { layer in
            layer.clip(to: body)
            for index in 0..<82 {
                let x = 104 + Double(index) * 1.4
                // Fine, low-contrast machining texture, generated from geometry.
                line(CGPoint(x: x, y: 55), CGPoint(x: x, y: 435),
                     color: .white.opacity(index.isMultiple(of: 3) ? 0.018 : 0.006), width: 0.35, in: &layer)
            }
            layer.fill(Path(CGRect(x: 103, y: 18, width: 114, height: 45)),
                       with: .linearGradient(Gradient(colors: [.white.opacity(0.045), .clear, .black.opacity(0.45)]),
                                             startPoint: CGPoint(x: 160, y: 20), endPoint: CGPoint(x: 160, y: 63)))
        }
        var capSeam = Path()
        capSeam.move(to: CGPoint(x: 104, y: 62))
        capSeam.addQuadCurve(to: CGPoint(x: 216, y: 62), control: CGPoint(x: 160, y: 58))
        context.stroke(capSeam, with: .color(.black.opacity(0.85)), lineWidth: 1)
        context.fill(Path(ellipseIn: CGRect(x: 136, y: 24, width: 48, height: 5)), with: .color(.black.opacity(0.4)))
        line(CGPoint(x: 104, y: 437), CGPoint(x: 216, y: 437), color: .black.opacity(0.6), width: 0.8, in: &context)
    }

    private func drawGrille(in context: inout GraphicsContext) {
        let grille = Path(roundedRect: CGRect(x: 105, y: 66, width: 110, height: 167), cornerRadius: 3)
        if emission > 0 {
            context.drawLayer { glow in
                glow.addFilter(.blur(radius: 9))
                glow.fill(grille, with: .color(light.opacity(emission * 0.15)))
            }
        }
        context.fill(grille, with: .color(Color(white: 0.018)))
        context.drawLayer { mesh in
            mesh.clip(to: grille)
            var holes = Path()
            for row in -1..<28 {
                for column in -1..<19 {
                    let x = 105 + Double(column) * 6.5 + (row.isMultiple(of: 2) ? 0 : 3.25)
                    let y = 68 + Double(row) * 6.0
                    var vertices: [CGPoint] = []
                    for corner in 0..<6 {
                        let angle = Double(corner) * .pi / 3 - .pi / 2
                        let flatX = x + cos(angle) * 3.0
                        // Cylinder projection compresses the mesh near both edges.
                        let projectedX = 160 + sin((flatX - 160) / 55 * .pi / 2) * 55
                        vertices.append(CGPoint(x: projectedX, y: y + sin(angle) * 3.3))
                    }
                    holes.addLines(vertices)
                    holes.closeSubpath()
                }
            }
            mesh.fill(holes, with: .color(light))
            mesh.stroke(holes, with: .color(.white.opacity(0.06)), lineWidth: 0.3)
            mesh.fill(grille, with: .linearGradient(Gradient(stops: [
                .init(color: .black.opacity(0.78), location: 0),
                .init(color: .black.opacity(0.1), location: 0.16),
                .init(color: .clear, location: 0.35),
                .init(color: .clear, location: 0.65),
                .init(color: .black.opacity(0.15), location: 0.86),
                .init(color: .black.opacity(0.82), location: 1)
            ]), startPoint: CGPoint(x: 105, y: 0), endPoint: CGPoint(x: 215, y: 0)))
        }
        context.stroke(grille, with: .color(.black.opacity(0.7)), lineWidth: 0.7)
    }

    private func drawFrontSuspension(in context: inout GraphicsContext) {
        for y in [252.0, 372] {
            let clamp = Path(roundedRect: CGRect(x: 92, y: y, width: 136, height: 20), cornerRadius: 2)
            context.fill(clamp, with: metal(from: 92, to: 228))
            context.stroke(clamp, with: .color(.white.opacity(0.07)), lineWidth: 0.7)
            for x in [104.0, 212] {
                let hinge = Path(roundedRect: CGRect(x: x, y: y, width: 5, height: 20), cornerRadius: 1)
                context.fill(hinge, with: metal(from: x, to: x + 5))
                line(CGPoint(x: x + 1, y: y + 1), CGPoint(x: x + 1, y: y + 19),
                     color: .white.opacity(0.25), width: 0.6, in: &context)
            }
            screw(at: CGPoint(x: 160, y: y + 10), in: &context)
        }
        for x in [111.0, 206] {
            for y in [267.0, 345] {
                let support = Path(roundedRect: CGRect(x: x, y: y, width: 3, height: 27), cornerRadius: 1.5)
                context.fill(support, with: .linearGradient(Gradient(colors: [Color(white: 0.63), Color(white: 0.23), Color(white: 0.5)]),
                                                          startPoint: CGPoint(x: x, y: 0), endPoint: CGPoint(x: x + 3, y: 0)))
            }
        }
        mountRing(at: 297, in: &context)
        mountRing(at: 340, in: &context)
    }

    private func mountRing(at y: CGFloat, in context: inout GraphicsContext) {
        let top = Path(ellipseIn: CGRect(x: 54, y: y - 4, width: 212, height: 12))
        context.fill(top, with: .color(Color(white: 0.075)))
        context.stroke(top, with: .color(.white.opacity(0.12)), lineWidth: 0.65)
        var front = Path()
        front.move(to: CGPoint(x: 54, y: y + 1))
        front.addQuadCurve(to: CGPoint(x: 266, y: y + 1), control: CGPoint(x: 160, y: y + 12))
        front.addLine(to: CGPoint(x: 266, y: y + 7))
        front.addQuadCurve(to: CGPoint(x: 54, y: y + 7), control: CGPoint(x: 160, y: y + 18))
        front.closeSubpath()
        context.fill(front, with: .linearGradient(Gradient(colors: [Color(white: 0.12), Color(white: 0.025)]),
                                                startPoint: CGPoint(x: 160, y: y), endPoint: CGPoint(x: 160, y: y + 14)))
        line(CGPoint(x: 55, y: y + 1), CGPoint(x: 265, y: y + 1), color: .white.opacity(0.035), width: 0.5, in: &context)
    }

    private func drawControls(in context: inout GraphicsContext) {
        // Neutral gain markers, without a wordmark or any decorative lettering.
        var pointer = Path()
        pointer.addLines([CGPoint(x: 157, y: 430), CGPoint(x: 163, y: 430), CGPoint(x: 160, y: 434)])
        pointer.closeSubpath()
        context.fill(pointer, with: .color(Color(white: 0.47)))
        for index in 0..<5 {
            let diameter = 3.4 - Double(index) * 0.35
            let rect = CGRect(x: 142 + Double(index) * 8, y: 442, width: diameter, height: diameter)
            context.fill(Path(ellipseIn: rect), with: .color(Color(white: 0.49 - Double(index) * 0.035)))
        }
    }

    private func screw(at point: CGPoint, in context: inout GraphicsContext) {
        let rim = Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8))
        context.fill(rim, with: .color(Color(white: 0.025)))
        context.stroke(rim, with: .color(.white.opacity(0.18)), lineWidth: 0.55)
        line(CGPoint(x: point.x - 1.8, y: point.y), CGPoint(x: point.x + 1.8, y: point.y),
             color: .white.opacity(0.16), width: 0.6, in: &context)
    }

    private func metal(from start: CGFloat, to end: CGFloat) -> GraphicsContext.Shading {
        .linearGradient(Gradient(stops: [
            .init(color: Color(white: 0.025), location: 0),
            .init(color: Color(white: 0.11), location: 0.08),
            .init(color: Color(white: 0.18), location: 0.23),
            .init(color: Color(white: 0.09), location: 0.47),
            .init(color: Color(white: 0.035), location: 0.79),
            .init(color: Color(white: 0.09), location: 0.95),
            .init(color: Color(white: 0.025), location: 1)
        ]), startPoint: CGPoint(x: start, y: 0), endPoint: CGPoint(x: end, y: 0))
    }

    private func line(_ start: CGPoint, _ end: CGPoint, color: Color, width: CGFloat, in context: inout GraphicsContext) {
        var path = Path()
        path.move(to: start); path.addLine(to: end)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }
}
