//
//  TimerModel.swift
//  TimeViewer
//
//  The Timer value type and the TimerStore single source of truth.
//

import Foundation
import Combine

/// A single countdown. Progress is derived from `startDate` + `duration` against
/// a reference "now", so it never drifts even if ticks are missed.
struct TimerModel: Identifiable {
    let id: UUID
    var name: String
    let duration: TimeInterval
    let startDate: Date

    init(id: UUID = UUID(), name: String, duration: TimeInterval, startDate: Date = Date()) {
        self.id = id
        self.name = name
        self.duration = duration
        self.startDate = startDate
    }

    /// Seconds remaining, clamped to `0`.
    func remaining(at now: Date) -> TimeInterval {
        max(0, duration - now.timeIntervalSince(startDate))
    }

    /// Completion fraction in `0...1`.
    func progress(at now: Date) -> Double {
        guard duration > 0 else { return 1 }
        let elapsed = now.timeIntervalSince(startDate)
        return min(1, max(0, elapsed / duration))
    }

    func isFinished(at now: Date) -> Bool {
        remaining(at: now) <= 0
    }
}

/// Holds all active timers and a one-second clock that drives the UI.
/// Injected via `.environmentObject`; the single source of truth.
final class TimerStore: ObservableObject {
    @Published private(set) var timers: [TimerModel] = []
    @Published private(set) var now: Date = Date()

    private var ticker: AnyCancellable?
    /// Timers we've already notified about, so each fires its alert exactly once.
    private var notifiedIDs: Set<TimerModel.ID> = []

    init() {
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.tick(date)
            }
    }

    private func tick(_ date: Date) {
        now = date
        for timer in timers where timer.isFinished(at: date) && !notifiedIDs.contains(timer.id) {
            notifiedIDs.insert(timer.id)
            NotificationManager.shared.notifyTimerFinished(name: timer.name)
        }
    }

    func addTimer(name: String, duration: TimeInterval) {
        timers.append(TimerModel(name: name, duration: duration))
    }

    func remove(_ id: TimerModel.ID) {
        timers.removeAll { $0.id == id }
        notifiedIDs.remove(id)
    }
}
