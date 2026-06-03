//
//  AddTimerView.swift
//  TimeViewer
//
//  Inline form for creating a timer: a unified field accepting a duration
//  ("25m", "1h30") or a target time ("@14:30", "@2pm"), a live preview of what
//  it resolved to, and an auto-filled, editable name.
//  Enter confirms, Escape cancels.
//

import SwiftUI

struct AddTimerView: View {
    @EnvironmentObject private var store: TimerStore
    @Binding var isPresented: Bool

    @State private var inputText = ""
    /// User-typed name. Empty means "follow the auto-generated label".
    @State private var nameOverride = ""
    @FocusState private var focusedField: Field?

    private enum Field { case input, name }

    /// Parsed against `store.now` so the target preview ticks down live.
    private var parsed: DurationParser.Result? {
        DurationParser.parse(inputText, now: store.now)
    }

    /// Default name derived from the parsed input.
    private var autoName: String {
        guard let parsed else { return "" }
        return DurationParser.defaultName(for: parsed)
    }

    /// Shows the auto name until the user types their own; clearing reverts to auto.
    private var nameBinding: Binding<String> {
        Binding(
            get: { nameOverride.isEmpty ? autoName : nameOverride },
            set: { nameOverride = $0 }
        )
    }

    var body: some View {
        VStack(spacing: 8) {
            TextField("25m, 1h30, @14:30, @2pm…", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .input)
                .onSubmit(confirm)

            if let parsed {
                Text(DurationParser.previewText(for: parsed, now: store.now))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            TextField("Name", text: nameBinding)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .name)
                .onSubmit(confirm)

            HStack {
                Button("Cancel", action: cancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(action: confirm) {
                    Image(systemName: "plus")
                        .frame(minWidth: 16)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(parsed == nil)
            }
        }
        .padding(12)
        .onAppear { focusedField = .input }
    }

    private func confirm() {
        guard let parsed else { return }
        let duration = DurationParser.remaining(for: parsed, now: Date())
        guard duration > 0 else { return }

        let trimmed = nameBinding.wrappedValue.trimmingCharacters(in: .whitespaces)
        store.addTimer(name: trimmed.isEmpty ? autoName : trimmed, duration: duration)
        isPresented = false
    }

    private func cancel() {
        isPresented = false
    }
}
