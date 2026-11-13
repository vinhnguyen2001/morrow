import Foundation

/// Date strings for Home projections. Formats with the calendar's own locale and time zone, never the device's,
/// so fixtures and tests are deterministic.
enum DateText {
    static func format(
        _ date: Date, calendar: Calendar, _ build: (Date.FormatStyle) -> Date.FormatStyle
    ) -> String {
        let base = Date.FormatStyle(
            locale: calendar.locale ?? .current, calendar: calendar, timeZone: calendar.timeZone
        )
        return date.formatted(build(base))
    }

    /// "Nov 12", with the year ("Nov 12, 2025") when it differs from the current year.
    /// Used for "since", note cards and "Last:" on place cards.
    static func short(_ date: Date, calendar: Calendar, now: Date) -> String {
        let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)
        return format(date, calendar: calendar) { sameYear ? $0.month(.abbreviated).day() : $0.month(.abbreviated).day().year() }
    }
}
