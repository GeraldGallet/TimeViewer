//
//  PresetStore.swift
//  TimeViewer
//
//  Single source of truth for the user's quick-launch presets. Persists to
//  UserDefaults; seeded with sensible defaults on first launch.
//

import Foundation
import Combine

final class PresetStore: ObservableObject {
    @Published var presets: [Preset] {
        didSet { save() }
    }

    private static let storageKey = "presets"

    static let defaults: [Preset] = [
        Preset(name: "1h", input: "1h"),
        Preset(name: "5pm", input: "@5pm"),
    ]

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([Preset].self, from: data) {
            presets = decoded
        } else {
            presets = Self.defaults
        }
    }

    func addBlank() {
        presets.append(Preset(name: "", input: ""))
    }

    func remove(_ id: Preset.ID) {
        presets.removeAll { $0.id == id }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}
