//
//  PresetChipsView.swift
//  TimeViewer
//
//  A horizontal row of quick-launch preset chips. Tapping a chip immediately
//  starts a timer from that preset (resolving "@5pm"-style inputs against now).
//  Renders nothing when there are no launchable presets.
//

import SwiftUI

struct PresetChipsView: View {
    @EnvironmentObject private var store: TimerStore
    @EnvironmentObject private var presetStore: PresetStore

    var body: some View {
        let launchable = presetStore.presets.filter { DurationParser.parse($0.input) != nil }
        if !launchable.isEmpty {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(launchable) { preset in
                            Button {
                                launch(preset)
                            } label: {
                                Text(label(for: preset))
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(1)
                            }
                            .buttonStyle(ChipButtonStyle())
                            .help("Start a timer: \(preset.input)")
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
                Divider()
            }
        }
    }

    /// Chip label: the preset's name, or a formatted fallback from its input.
    private func label(for preset: Preset) -> String {
        if !preset.name.isEmpty { return preset.name }
        if let parsed = DurationParser.parse(preset.input) {
            return DurationParser.defaultName(for: parsed)
        }
        return preset.input
    }

    private func launch(_ preset: Preset) {
        let now = Date()
        guard let parsed = DurationParser.parse(preset.input, now: now) else { return }
        let duration = DurationParser.remaining(for: parsed, now: now)
        guard duration > 0 else { return }
        let name = preset.name.isEmpty ? DurationParser.defaultName(for: parsed) : preset.name
        store.addTimer(name: name, duration: duration)
    }
}

/// Pill-shaped button with a hover/press highlight, used for preset chips.
private struct ChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Chip(configuration: configuration)
    }

    private struct Chip: View {
        let configuration: ButtonStyleConfiguration
        @State private var isHovering = false

        var body: some View {
            configuration.label
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.primary.opacity(fill)))
                .contentShape(Capsule())
                .onHover { isHovering = $0 }
        }

        private var fill: Double {
            if configuration.isPressed { return 0.22 }
            if isHovering { return 0.16 }
            return 0.10
        }
    }
}
