//
//  TimerRowView.swift
//  TimeViewer
//
//  One timer row: name, progress bar, percentage, time remaining, stop button.
//  Reused by the popover (and the floating widget in Iteration 2).
//

import SwiftUI

struct TimerRowView: View {
    let timer: TimerModel
    let now: Date
    let onStop: () -> Void

    var body: some View {
        let progress = timer.progress(at: now)
        let remaining = timer.remaining(at: now)
        let finished = timer.isFinished(at: now)

        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(timer.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                if finished {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 12))
                }
                Spacer(minLength: 8)
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Button(action: onStop) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                }
                .buttonStyle(HoverButtonStyle(padding: EdgeInsets(top: 3, leading: 3, bottom: 3, trailing: 3)))
                .foregroundStyle(.secondary)
                .help("Stop timer")
            }

            ProgressView(value: progress)
                .tint(finished ? .green : .accentColor)

            Text(DurationParser.formatRemaining(remaining))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(finished ? .green : .secondary)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 12)
    }
}
