//
//  WidgetSettings.swift
//  TimeViewer
//
//  User-tunable widget appearance settings, shared with the floating widget.
//  Persisted to UserDefaults so the choice survives relaunch.
//

import Foundation
import Combine

final class WidgetSettings: ObservableObject {
    /// Widget background opacity, clamped to 0.1...1.0.
    @Published var opacity: Double {
        didSet {
            let clamped = min(max(opacity, Self.minOpacity), Self.maxOpacity)
            if clamped != opacity {
                opacity = clamped
                return
            }
            UserDefaults.standard.set(opacity, forKey: Self.opacityKey)
        }
    }

    static let minOpacity = 0.1
    static let maxOpacity = 1.0
    private static let defaultOpacity = 0.7
    private static let opacityKey = "widgetOpacity"

    init() {
        let saved = UserDefaults.standard.double(forKey: Self.opacityKey)
        // `double(forKey:)` returns 0 when unset — fall back to the default then.
        opacity = saved == 0 ? Self.defaultOpacity : min(max(saved, Self.minOpacity), Self.maxOpacity)
    }
}
