import Foundation
@testable import Morrow

/// Shared fixtures for projection tests: a fixed calendar (UTC+7, en_GB) and quick builders.
enum ProjectionTestSupport {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .gmt
        calendar.locale = Locale(identifier: "en_GB")
        return calendar
    }()

    static func date(_ day: Int, _ hour: Int = 12, month: Int = 11, year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? .distantPast
    }

    /// "now" for projections: 2026-11-12 20:00.
    static var now: Date { date(12, 20) }

    static func memory(
        _ n: Int, kind: MemoryKind = .note, title: String? = nil, body: String? = nil,
        place: String? = nil, photo: String? = nil, at when: Date
    ) -> Memory {
        Memory(id: UUID(uuidString: String(format: "A1000000-0000-0000-0000-%012d", n))!,
               kind: kind, title: title ?? "Memory \(n)", body: body, placeName: place,
               photoFileName: photo, createdAt: when)
    }
}
