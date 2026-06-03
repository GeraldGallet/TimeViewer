//
//  FloatingWidgetView.swift
//  TimeViewer
//
//  SwiftUI content for the floating widget: a translucent, rounded card showing
//  the active timers (or "No timer") plus an inline add-timer form.
//

import SwiftUI

struct FloatingWidgetView: View {
    @EnvironmentObject private var store: TimerStore
    @EnvironmentObject private var settings: WidgetSettings
    @State private var isAdding = false

    /// Called when the user clicks the widget's close button.
    let onClose: () -> Void

    private let cornerRadius: CGFloat = 14

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            PresetChipsView()

            if store.timers.isEmpty {
                emptyState
            } else {
                ForEach(Array(store.timers.enumerated()), id: \.element.id) { index, timer in
                    if index > 0 { Divider() }
                    TimerRowView(timer: timer, now: store.now) {
                        store.remove(timer.id)
                    }
                }
            }

            if isAdding {
                Divider()
                AddTimerView(isPresented: $isAdding)
            }

            Divider()
            footer
        }
        .frame(width: 320)
        .background(Color(nsColor: .windowBackgroundColor).opacity(settings.opacity))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        // Transparent margin so the window shadow and rounded corners aren't clipped.
        .padding(8)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("Time Viewer")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            Image(systemName: "circle.righthalf.filled")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Slider(value: $settings.opacity, in: WidgetSettings.minOpacity...WidgetSettings.maxOpacity)
                .controlSize(.mini)
                .frame(width: 90)
                .help("Widget opacity")

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(HoverButtonStyle(padding: EdgeInsets(top: 3, leading: 3, bottom: 3, trailing: 3)))
            .foregroundStyle(.secondary)
            .help("Hide widget")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
    }

    private var emptyState: some View {
        Text("No timer")
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
    }

    private var footer: some View {
        HStack {
            Button {
                isAdding = true
            } label: {
                Label("Add timer", systemImage: "plus")
            }
            .buttonStyle(HoverButtonStyle())
            .disabled(isAdding)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}
