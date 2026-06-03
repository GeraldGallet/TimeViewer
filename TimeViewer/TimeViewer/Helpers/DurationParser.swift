//
//  DurationParser.swift
//  TimeViewer
//
//  Parses human-typed input into either a duration or a target clock time,
//  and formats TimeIntervals/targets back into readable strings.
//

import Foundation

enum DurationParser {

    /// The two things a user can type into the timer field.
    enum Result: Equatable {
        /// A length of time, in seconds (e.g. "25m", "1h30").
        case duration(TimeInterval)
        /// An absolute clock time to count down to (e.g. "@14:30", "@2pm").
        case target(Date)
    }

    /// Parses input into a duration or a target time.
    ///
    /// Durations (case-insensitive, whitespace tolerant):
    /// - `25m`, `1h`, `1h30` / `1h 30m`, `90m`, `30s`, bare `25` → minutes
    ///
    /// Targets (prefixed with `@`):
    /// - 24-hour: `@14`, `@14h`, `@14:30`, `@14h30`
    /// - 12-hour: `@2pm`, `@2:30pm`, `@11am`, `@11:45pm`
    /// - If the time has already passed today, it resolves to tomorrow.
    ///
    /// Returns `nil` for empty or unparseable input.
    static func parse(_ input: String, now: Date = Date()) -> Result? {
        let text = input.lowercased().trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }

        if text.hasPrefix("@") {
            return parseTarget(String(text.dropFirst()), now: now)
        }
        if let seconds = parseDuration(text) {
            return .duration(seconds)
        }
        return nil
    }

    // MARK: - Derived values

    /// Seconds remaining for a parsed result, relative to `now`.
    static func remaining(for result: Result, now: Date = Date()) -> TimeInterval {
        switch result {
        case .duration(let seconds): return max(0, seconds)
        case .target(let date):      return max(0, date.timeIntervalSince(now))
        }
    }

    /// Default timer name for a parsed result ("1h 30min" or "until 14:30").
    static func defaultName(for result: Result) -> String {
        switch result {
        case .duration(let seconds): return format(duration: seconds)
        case .target(let date):      return "until \(clockString(date))"
        }
    }

    /// Read-only confirmation line shown under the input field.
    static func previewText(for result: Result, now: Date = Date()) -> String {
        switch result {
        case .duration(let seconds):
            return "→ \(format(duration: seconds))"
        case .target(let date):
            let remaining = max(0, date.timeIntervalSince(now))
            return "→ until \(clockString(date)) · \(format(duration: remaining)) remaining"
        }
    }

    // MARK: - Duration parsing

    /// Parses a bare duration string (no `@` prefix) into seconds.
    private static func parseDuration(_ text: String) -> TimeInterval? {
        // Reject anything that isn't a sequence of "<number><optional h/m/s>".
        let shape = #"^(\s*\d+\s*[hms]?\s*)+$"#
        guard text.range(of: shape, options: .regularExpression) != nil else { return nil }

        let pairPattern = #"(\d+)\s*([hms]?)"#
        guard let regex = try? NSRegularExpression(pattern: pairPattern) else { return nil }
        let fullRange = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: fullRange)
        guard !matches.isEmpty else { return nil }

        var total: TimeInterval = 0
        for match in matches {
            guard let numberRange = Range(match.range(at: 1), in: text),
                  let value = Double(text[numberRange]) else { return nil }

            let unit = Range(match.range(at: 2), in: text).map { String(text[$0]) } ?? ""
            switch unit {
            case "h": total += value * 3600
            case "s": total += value
            // "m" and bare numbers both count as minutes.
            default:  total += value * 60
            }
        }

        return total > 0 ? total : nil
    }

    // MARK: - Target-time parsing

    /// Parses the body after `@` into a target `Date` (today, or tomorrow if past).
    private static func parseTarget(_ raw: String, now: Date) -> Result? {
        var text = raw.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }

        // Pull off an am/pm suffix if present.
        var meridiem: String?
        if text.hasSuffix("pm") { meridiem = "pm"; text = String(text.dropLast(2)) }
        else if text.hasSuffix("am") { meridiem = "am"; text = String(text.dropLast(2)) }
        text = text.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }

        // Normalize the "h" separator: a trailing "h" means hour-only ("14h"),
        // an internal "h" is a separator ("14h30" → "14:30").
        if text.hasSuffix("h") { text = String(text.dropLast()) }
        text = text.replacingOccurrences(of: "h", with: ":")

        let parts = text.split(separator: ":", omittingEmptySubsequences: false)
        guard (1...2).contains(parts.count) else { return nil }
        guard !parts[0].isEmpty, parts[0].allSatisfy(\.isNumber),
              let rawHour = Int(parts[0]) else { return nil }

        var minute = 0
        if parts.count == 2 {
            guard !parts[1].isEmpty, parts[1].allSatisfy(\.isNumber),
                  let parsedMinute = Int(parts[1]) else { return nil }
            minute = parsedMinute
        }
        guard (0...59).contains(minute) else { return nil }

        let hour: Int
        if let meridiem {
            guard (1...12).contains(rawHour) else { return nil }
            if meridiem == "pm" {
                hour = rawHour == 12 ? 12 : rawHour + 12
            } else {
                hour = rawHour == 12 ? 0 : rawHour
            }
        } else {
            guard (0...23).contains(rawHour) else { return nil }
            hour = rawHour
        }

        return targetDate(hour: hour, minute: minute, now: now).map { .target($0) }
    }

    /// Builds the next occurrence of `hour:minute`, rolling to tomorrow if it's already past.
    private static func targetDate(hour: Int, minute: Int, now: Date) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0
        guard let candidate = calendar.date(from: components) else { return nil }
        if candidate <= now {
            return calendar.date(byAdding: .day, value: 1, to: candidate)
        }
        return candidate
    }

    // MARK: - Formatting

    /// Compact label for a duration, used as the default timer name.
    /// e.g. `5400s → "1h 30min"`, `1500s → "25min"`, `30s → "30s"`.
    static func format(duration: TimeInterval) -> String {
        let total = max(0, Int(duration.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        var parts: [String] = []
        if hours > 0 { parts.append("\(hours)h") }
        if minutes > 0 { parts.append("\(minutes)min") }
        if seconds > 0 { parts.append("\(seconds)s") }
        return parts.isEmpty ? "0s" : parts.joined(separator: " ")
    }

    /// Spaced label for time remaining, shown on each row.
    /// e.g. `872s → "14 min 32 s"`, `0s → "0 s"`.
    static func formatRemaining(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.up)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        var parts: [String] = []
        if hours > 0 { parts.append("\(hours) h") }
        if hours > 0 || minutes > 0 { parts.append("\(minutes) min") }
        parts.append("\(seconds) s")
        return parts.joined(separator: " ")
    }

    /// 24-hour clock string for a target, e.g. "14:30".
    private static func clockString(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
}
