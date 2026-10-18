//
//  ContentView.swift
//  QuadCastControl
//
//  Created by ByteHasher on 18.10.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)

            Text("QuadCast Control")
                .font(.title2.weight(.semibold))

            Label("No microphone connected", systemImage: "circle.fill")
                .labelStyle(StatusLabelStyle(color: .orange))
                .foregroundStyle(.secondary)

            Text("Connect your HyperX microphone via USB.")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
        .padding(40)
        .frame(minWidth: 420, minHeight: 300)
    }
}

private struct StatusLabelStyle: LabelStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon
                .font(.system(size: 8))
                .foregroundStyle(color)
            configuration.title
        }
    }
}

#Preview {
    ContentView()
}
