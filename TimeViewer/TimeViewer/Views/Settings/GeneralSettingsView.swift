//
//  GeneralSettingsView.swift
//  TimeViewer
//
//  General settings tab: widget appearance.
//

import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject private var settings: WidgetSettings

    var body: some View {
        Form {
            Section("Floating widget") {
                HStack {
                    Text("Opacity")
                    Slider(value: $settings.opacity,
                           in: WidgetSettings.minOpacity...WidgetSettings.maxOpacity)
                    Text("\(Int((settings.opacity * 100).rounded()))%")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .formStyle(.grouped)
    }
}
