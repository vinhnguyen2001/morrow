#if DEBUG
import Foundation
import UIKit

/// Debug-only screenshot fixtures: launch with `-MorrowFixtures` (add `empty` for no memories).
/// Everything lives in memory or in a temporary folder, so the real store and photos are never opened
/// (the composition root returns before `makeContainer`, which would create or move the real store).
/// Fixed IDs, dates and colours make every run render the same.
enum LaunchFixtures {
    static let argument = "-MorrowFixtures"

    /// Fixed "now" for fixtures: 2026-11-12 20:30 in Ho Chi Minh City (UTC+7).
    static let now = Date(timeIntervalSince1970: 1_794_490_200)
    static let timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .gmt

    static var requested: Bool { ProcessInfo.processInfo.arguments.contains(argument) }

    /// The word after a launch argument, if any.
    private static func value(after flag: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: flag), index + 1 < args.count else { return nil }
        return args[index + 1]
    }

    private static var wantsEmpty: Bool { value(after: argument) == "empty" }

    /// `-MorrowFixtureOpen <n>` opens the detail of fixture memory n (1 to 8), or `map` opens the Map, for screenshots.
    static var initialPath: [Route] {
        guard let value = value(after: "-MorrowFixtureOpen") else { return [] }
        if value == "map" { return [.map] }
        guard let number = Int(value), (1...8).contains(number) else { return [] }
        return [.memory(id(number))]
    }

    /// `-MorrowFixtureTab moments|notes|places` opens Home on that tab, for screenshots.
    static var initialTab: HomeTab {
        value(after: "-MorrowFixtureTab").flatMap(HomeTab.init(rawValue:)) ?? .moments
    }

    /// `-MorrowFixtureMapSelect <n>` opens the Map with fixture memory n selected (peek sheet up);
    /// add `-MorrowFixtureMapLarge` to start with the sheet expanded to Detail.
    static var mapSelection: UUID? {
        guard let value = value(after: "-MorrowFixtureMapSelect"), let number = Int(value), (1...8).contains(number) else { return nil }
        return id(number)
    }
    static var mapLarge: Bool { ProcessInfo.processInfo.arguments.contains("-MorrowFixtureMapLarge") }

    /// `-MorrowFixtureMapPins <n>` adds n generated memories with coordinates (no photos), to measure pan and zoom on a device.
    private static var extraPinCount: Int { value(after: "-MorrowFixtureMapPins").flatMap(Int.init).map { min(max($0, 0), 1000) } ?? 0 }

    /// `-MorrowFixtureCapture locating|located|denied` opens the Capture sheet with a fake location source.
    enum CaptureMode: String { case locating, located, denied }

    static var captureMode: CaptureMode? {
        return value(after: "-MorrowFixtureCapture").flatMap(CaptureMode.init)
    }

    /// Fake location for screenshots only: no CoreLocation, no permission prompt, no real position.
    @MainActor
    private final class FixtureLocation: LocationProviding, PlaceNaming {
        let mode: CaptureMode
        init(_ mode: CaptureMode) { self.mode = mode }
        var authorization: LocationAuthorization { mode == .denied ? .denied : .authorized }
        func requestWhenInUse() async {}
        func currentCoordinate() async -> Coordinate? {
            switch mode {
            case .denied: return nil
            case .locating: try? await Task.sleep(for: .seconds(3600)); return nil
            case .located: return Coordinate(latitude: 10.0, longitude: 100.0)
            }
        }
        nonisolated func placeName(for coordinate: Coordinate) async -> String? { "Fixture Market, Fixture City" }
    }

    @MainActor
    static func makeModel() -> HomeViewModel {
        // In-memory container: never touches Application Support. Failure is a programmer error in a debug tool.
        guard let container = try? SwiftDataMemoryRepository.makeContainer(inMemory: true) else {
            fatalError("Fixture container failed")
        }
        let repository = SwiftDataMemoryRepository(container: container)
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "MorrowFixturePhotos", directoryHint: .isDirectory)
        try? FileManager.default.removeItem(at: directory)
        let photoStore = PhotoStore(directory: directory)
        if !wantsEmpty {
            for memory in memories(photoStore: photoStore) + generatedPins(count: extraPinCount) { try? repository.add(memory) }
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "en_US")
        let location = captureMode.map(FixtureLocation.init)
        let provider: LocationProviding = location ?? NoLocationProvider()
        let namer: PlaceNaming = location ?? NoPlaceNamer()
        return HomeViewModel(repository: repository, photoStore: photoStore,
                             locationProvider: provider, placeNamer: namer,
                             calendar: calendar, now: { now })
    }

    // Force unwraps are intended: compile-time UUID literals (notes/sample-data.md).
    private static func id(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "F1000000-0000-0000-0000-%012d", n))!
    }

    /// Fake positions around central Vietnam for the Map. Fixtures 3 and 5 have none, to exercise the filter.
    private static let coordinates: [Int: Coordinate] = [
        1: Coordinate(latitude: 15.8801, longitude: 108.3380), 2: Coordinate(latitude: 16.0544, longitude: 108.2022),
        4: Coordinate(latitude: 15.8770, longitude: 108.3265), 6: Coordinate(latitude: 15.8520, longitude: 108.2760),
        7: Coordinate(latitude: 16.4637, longitude: 107.5909), 8: Coordinate(latitude: 21.0285, longitude: 105.8542),
    ].compactMapValues { $0 }

    /// Deterministic grid-with-jitter of notes inside Vietnam, in memory only. No photos: cheap to build.
    private static func generatedPins(count: Int) -> [Memory] {
        (0..<count).map { i in
            let latitude = 10.0 + Double(i % 25) * 0.45 + Double((i * 7) % 10) * 0.01
            let longitude = 104.0 + Double(i / 25) * 0.6 + Double((i * 3) % 10) * 0.01
            return Memory(id: UUID(uuidString: String(format: "F2000000-0000-0000-0000-%012d", i))!,
                          kind: i % 3 == 0 ? .photo : .note, title: "Pin \(i + 1)", placeName: "Fixture place \(i % 40)",
                          coordinate: Coordinate(latitude: latitude, longitude: longitude),
                          createdAt: now.addingTimeInterval(-Double(i) * 600))
        }
    }

    private static func memories(photoStore: PhotoStore) -> [Memory] {
        func photo(_ n: Int, _ title: String, _ place: String?, hoursAgo: Double, colors: (UInt32, UInt32)) -> Memory {
            let fileName = try? photoStore.save(imageData: gradientJPEG(colors), id: id(n))
            return Memory(id: id(n), kind: .photo, title: title, placeName: place, coordinate: coordinates[n],
                          photoFileName: fileName, createdAt: now.addingTimeInterval(-hoursAgo * 3600))
        }
        func note(_ n: Int, _ title: String, _ body: String?, _ place: String?, hoursAgo: Double) -> Memory {
            Memory(id: id(n), kind: .note, title: title, body: body, placeName: place, coordinate: coordinates[n],
                   createdAt: now.addingTimeInterval(-hoursAgo * 3600))
        }
        return [
            photo(1, "Sunrise over the old harbour", "Hội An", hoursAgo: 2, colors: (0xF2B880, 0xD86C5A)),
            note(2, "Best coffee so far", "Tiny shop behind the market. Ask for the salted version and stay for a second cup.", "Đà Nẵng", hoursAgo: 5),
            photo(3, "Rooftop with friends", nil, hoursAgo: 8, colors: (0x7FB3D5, 0x2E5E8C)),
            photo(4, "Lanterns on the river", "Hội An", hoursAgo: 27, colors: (0xE8C468, 0x8E5B3A)),
            note(5, "Remember to call Mom", nil, nil, hoursAgo: 30),
            photo(6, "Market morning", "Thu Bồn", hoursAgo: 61, colors: (0x8FCB9B, 0x2F6B4F)),
            note(7, "Train to Huế leaves at nine, bring snacks and the blue charger", "Window seat on the left side for the sea view. The ticket says platform four, but the board has been wrong before, so ask at the desk. Pack sandwiches, water and the small umbrella; the coast road floods after noon and the driver always waits for stragglers. Message Linh when we pass Lăng Cô, she wanted a photo of the bay from the tunnel exit.", "Đà Nẵng", hoursAgo: 80),
            photo(8, "First night in the city", "Hà Nội", hoursAgo: 240, colors: (0xB9A3E3, 0x5B3FB8)),
        ]
    }

    /// Gradient image generated in code, so no photo ever has to be bundled or read.
    private static func gradientJPEG(_ colors: (UInt32, UInt32)) -> Data {
        let size = CGSize(width: 600, height: 450)
        func color(_ hex: UInt32) -> CGColor {
            UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                    blue: CGFloat(hex & 0xFF) / 255, alpha: 1).cgColor
        }
        return UIGraphicsImageRenderer(size: size).jpegData(withCompressionQuality: 0.9) { context in
            let space = CGColorSpaceCreateDeviceRGB()
            guard let gradient = CGGradient(colorsSpace: space, colors: [color(colors.0), color(colors.1)] as CFArray,
                                            locations: [0, 1]) else { return }
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        }
    }
}
#endif
