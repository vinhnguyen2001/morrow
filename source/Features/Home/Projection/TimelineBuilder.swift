import Foundation

/// One day's header in the timeline.
struct DayHeader: Equatable {
    let id: String
    let isToday: Bool
    let number: String
    /// "Today" for the current day, otherwise the weekday name.
    let weekday: String
    let monthYear: String
    /// One VoiceOver phrase, for example "Today, Thursday, November 12".
    let accessibilityLabel: String
}

/// One memory in the timeline with everything the row needs, already computed.
struct TimelineItem: Equatable {
    let id: String
    let memory: Memory
    let stagger: Stagger
    let dayPart: DayPart
    let timeText: String
}

enum TimelineRow: Equatable, Identifiable {
    case sprout
    case day(DayHeader)
    case memory(TimelineItem)
    case origin

    /// Stable: "sprout", "day-yyyy-MM-dd", "m-<uuid>", "origin".
    var id: String {
        switch self {
        case .sprout: return "sprout"
        case .day(let header): return header.id
        case .memory(let item): return item.id
        case .origin: return "origin"
        }
    }
}

struct Timeline: Equatable {
    var rows: [TimelineRow]
    /// "Sep 1" (adds the year when it differs from the current year). Nil when empty.
    var sinceText: String?

    static let empty = Timeline(rows: [], sinceText: nil)
}

/// Pure projection of memories into timeline rows. Calendar, locale (via the calendar) and `now` are inputs.
enum TimelineBuilder {
    static func build(memories: [Memory], calendar: Calendar, now: Date) -> Timeline {
        guard !memories.isEmpty else { return .empty }

        // Total order: createdAt, then id. The index in this order is the stagger index.
        let ascending = memories.sorted { ($0.createdAt, $0.id.uuidString) < ($1.createdAt, $1.id.uuidString) }
        let lastIndex = ascending.count - 1

        var rows: [TimelineRow] = [.sprout]
        rows.reserveCapacity(ascending.count * 2 + 2)
        var currentDay: Date?
        for (reverseIndex, memory) in ascending.reversed().enumerated() {
            let day = calendar.startOfDay(for: memory.createdAt)
            if day != currentDay {
                rows.append(.day(dayHeader(for: day, calendar: calendar, now: now)))
                currentDay = day
            }
            rows.append(.memory(TimelineItem(
                id: "m-\(memory.id.uuidString)",
                memory: memory,
                stagger: Stagger(index: lastIndex - reverseIndex),
                dayPart: DayPart(hour: calendar.component(.hour, from: memory.createdAt)),
                timeText: format(memory.createdAt, calendar: calendar) { $0.hour().minute() }
            )))
        }
        rows.append(.origin)

        let oldest = ascending[0].createdAt
        let sameYear = calendar.component(.year, from: oldest) == calendar.component(.year, from: now)
        let since = format(oldest, calendar: calendar) { sameYear ? $0.month(.abbreviated).day() : $0.month(.abbreviated).day().year() }
        return Timeline(rows: rows, sinceText: since)
    }

    private static func dayHeader(for day: Date, calendar: Calendar, now: Date) -> DayHeader {
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        let id = String(format: "day-%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
        let isToday = calendar.isDate(day, inSameDayAs: now)
        let weekdayName = format(day, calendar: calendar) { $0.weekday(.wide) }
        let spoken = format(day, calendar: calendar) { $0.weekday(.wide).month(.wide).day() }
        return DayHeader(
            id: id,
            isToday: isToday,
            number: format(day, calendar: calendar) { $0.day() },
            weekday: isToday ? "Today" : weekdayName,
            monthYear: format(day, calendar: calendar) { $0.month(.wide).year() },
            accessibilityLabel: isToday ? "Today, \(spoken)" : spoken
        )
    }

    /// Formats with the calendar's own locale and time zone, never the device's.
    private static func format(
        _ date: Date, calendar: Calendar, _ build: (Date.FormatStyle) -> Date.FormatStyle
    ) -> String {
        let base = Date.FormatStyle(
            locale: calendar.locale ?? .current, calendar: calendar, timeZone: calendar.timeZone
        )
        return date.formatted(build(base))
    }
}
