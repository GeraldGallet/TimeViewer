//
//  TimeViewerApp.swift
//  TimeViewer
//
//  App entry point. A menubar-only (accessory) app exposing a MenuBarExtra popover.
//

import SwiftUI

@main
struct TimeViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store: TimerStore
    @StateObject private var settings: WidgetSettings
    @StateObject private var presetStore: PresetStore
    @StateObject private var widget: WidgetController

    init() {
        let store = TimerStore()
        let settings = WidgetSettings()
        let presetStore = PresetStore()
        _store = StateObject(wrappedValue: store)
        _settings = StateObject(wrappedValue: settings)
        _presetStore = StateObject(wrappedValue: presetStore)
        _widget = StateObject(wrappedValue: WidgetController(store: store, settings: settings, presetStore: presetStore))
    }

    var body: some Scene {
        MenuBarExtra("Time Viewer", systemImage: "timer") {
            PopoverView()
                .environmentObject(store)
                .environmentObject(widget)
                .environmentObject(presetStore)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(presetStore)
        }
    }
}

/// Keeps the app out of the Dock and app switcher — it lives only in the menubar.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NotificationManager.shared.requestAuthorization()
    }
}
