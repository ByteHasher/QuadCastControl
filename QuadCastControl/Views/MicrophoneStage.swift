//
//  MicrophoneStage.swift
//  QuadCastControl
//
//  Created by ByteHasher on 19.10.2026.
//

import SwiftUI

struct MicrophoneStage: View {
    let microphone: Microphone?
    let draft: LightingDraft
    var height: CGFloat?

    var body: some View {
        GeometryReader { geometry in
            let artworkHeight = max(0, min(geometry.size.height - 30,
                                           geometry.size.width * 0.44 * 540 / 320))
            let artworkWidth = artworkHeight * 320 / 540
            ZStack {
                WorkspaceTheme.background
                RadialGradient(colors: [Color.purple.opacity(0.18), .clear], center: .bottomLeading,
                               startRadius: 0, endRadius: geometry.size.width * 0.8)
                RadialGradient(colors: [Color.green.opacity(0.07), .clear], center: .topTrailing,
                               startRadius: 0, endRadius: geometry.size.width * 0.75)
                if microphone == nil || microphone?.model == .quadCastS {
                    MicrophoneIllustration(color: draft.color, brightnessPercent: draft.brightnessPercent,
                                           isEnabled: draft.enabled)
                        .frame(width: artworkWidth, height: artworkHeight)
                        .offset(x: geometry.size.width * 0.05)
                } else {
                    Image(systemName: "mic.fill").font(.system(size: artworkHeight * 0.45, weight: .ultraLight))
                        .foregroundStyle(WorkspaceTheme.muted)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .overlay(alignment: .topLeading) {
                HStack(spacing: 8) {
                    Circle().fill(microphone == nil ? WorkspaceTheme.muted : WorkspaceTheme.connected).frame(width: 5, height: 5)
                    Text(microphone == nil ? LocalizedStringKey("workspace.waitingUSB") : LocalizedStringKey("workspace.usbConnected"))
                        .font(.system(size: 10, weight: .semibold)).tracking(1.6)
                }.foregroundStyle(.white.opacity(0.65)).padding(28)
            }
            .overlay(alignment: .bottom) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(verbatim: (microphone?.model.rawValue ?? "QuadCast S").uppercased())
                            .font(.system(size: 13, weight: .semibold)).tracking(3.5)
                        Text("workspace.preview").font(.system(size: 11)).foregroundStyle(WorkspaceTheme.muted)
                    }
                    Spacer()
                    Label("workspace.bothZones", systemImage: "square.stack.3d.up")
                        .font(.system(size: 11)).foregroundStyle(WorkspaceTheme.muted)
                }.padding(28)
            }
            .clipped()
        }
        .frame(height: height)
        .overlay(alignment: .bottom) { WorkspaceTheme.line.frame(height: 1) }
        .accessibilityElement(children: .combine)
    }
}
