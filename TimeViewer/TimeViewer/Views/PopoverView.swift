//
//  PopoverView.swift
//  TimeViewer
//
//  Main popover: empty state, list of active timers, inline add form, footer.
//

import SwiftUI

struct PopoverView: View {
    @EnvironmentObject private var store: TimerStore
    @EnvironmentObject private var widget: WidgetController
    @Environment(\.openSettings) private var openSettings
    @State private var isAdding = false

    private let width: CGFloat = 300

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            PresetChipsView()

            content

            if isAdding {
                Divider()
                AddTimerView(isPresented: $isAdding)
            }

            Divider()
            footer
        }
        .frame(width: width)
        .onAppear {
            // Become frontmost when the popover opens so the menu bar stays
            // pinned (otherwise auto-hide collapses the bar and dismisses us).
            NSApplication.shared.activate(ignoringOtherApps: true)
            // Hide the widget while the menu is open; it returns when the menu closes.
            widget.menuDidOpen()
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.timers.isEmpty {
            if !isAdding {
                emptyState
            }
        } else {
            timerList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
            Text("No active timers")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private var timerList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(store.timers.enumerated()), id: \.element.id) { index, timer in
                    if index > 0 { Divider() }
                    TimerRowView(timer: timer, now: store.now) {
                        store.remove(timer.id)
                    }
                }
            }
        }
        .frame(maxHeight: 280)
    }

    private var header: some View {
        HStack(spacing: 0) {
            Spacer()

            Button {
                widget.setEnabled(!widget.isEnabled)
            } label: {
                Image(systemName: "pip.enter")
                    .font(.system(size: 13))
            }
            .buttonStyle(HoverButtonStyle(padding: EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6)))
            .foregroundStyle(widget.isEnabled ? Color.accentColor : .secondary)
            .help(widget.isEnabled ? "Hide floating widget" : "Show floating widget")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
    }

    private var footer: some View {
        HStack {
            Button {
                NSApplication.shared.activate(ignoringOtherApps: true)
                openSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(HoverButtonStyle())
            .foregroundStyle(.secondary)
            .help("Settings")

            Button {
                isAdding = true
            } label: {
                Label("Add timer", systemImage: "plus")
            }
            .buttonStyle(HoverButtonStyle())
            .disabled(isAdding)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(HoverButtonStyle())
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}
