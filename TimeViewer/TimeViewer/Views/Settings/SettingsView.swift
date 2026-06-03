//
//  SettingsView.swift
//  TimeViewer
//
//  The app's Settings window (opened from the popover gear), with General and
//  Presets tabs.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
            PresetsSettingsView()
                .tabItem { Label("Presets", systemImage: "bookmark") }
        }
        .frame(width: 440, height: 320)
    }
}
