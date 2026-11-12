import Foundation

/// Fixture data. Used by the app target in M0, so it is not under `#if DEBUG`
/// until a real composition root exists.
extension Memory {
    // Force unwraps are intended: these are compile-time literals.
    // Dates are fixed literals so previews and tests are deterministic.
    static let samples: [Memory] = [
        Memory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
               kind: .photo, title: "Sunrise over the old harbour", placeName: "Hoi An",
               createdAt: Date(timeIntervalSince1970: 1_700_000_000)),
        Memory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
               kind: .note, title: "Best coffee so far",
               body: "Tiny shop behind the market. Ask for the salted version, sit by the window and stay for a second cup.",
               placeName: "Da Nang",
               createdAt: Date(timeIntervalSince1970: 1_700_003_600)),
        Memory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
               kind: .photo, title: "Rooftop with friends",
               createdAt: Date(timeIntervalSince1970: 1_700_007_200)),
        Memory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
               kind: .note, title: "Remember to call Mom",
               createdAt: Date(timeIntervalSince1970: 1_700_010_800)),
    ]
}
