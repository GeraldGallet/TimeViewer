//
//  PresetsSettingsView.swift
//  TimeViewer
//
//  Presets settings tab: add, rename, edit, and remove quick-launch presets.
//

import SwiftUI

struct PresetsSettingsView: View {
    @EnvironmentObject private var presetStore: PresetStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tap a preset chip in the popover or widget to start a timer. "
                 + "Use a duration (25m, 1h30) or a target time (@5pm, @14:30).")
                .font(.caption)
                .foregroundStyle(.secondary)

            List {
                ForEach($presetStore.presets) { $preset in
                    HStack(spacing: 8) {
                        TextField("Name", text: $preset.name)
                            .frame(width: 130)
                        TextField("25m, 1h30, @5pm", text: $preset.input)
                        if !preset.input.isEmpty, DurationParser.parse(preset.input) == nil {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .help("Not a valid duration or @time — this preset won't show as a chip")
                        }
                        Button {
                            presetStore.remove(preset.id)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .help("Remove preset")
                    }
                }
            }
            .frame(minHeight: 150)

            Button {
                presetStore.addBlank()
            } label: {
                Label("Add preset", systemImage: "plus")
            }
        }
        .padding()
    }
}
