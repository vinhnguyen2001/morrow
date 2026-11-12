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

    private static var wantsEmpty: Bool {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: argument), index + 1 < args.count else { return false }
        return args[index + 1] == "empty"
    }

    /// `-MorrowFixtureOpen <n>` opens the detail of fixture memory n (1 to 8) on launch, for screenshots.
    static var initialPath: [Route] {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-MorrowFixtureOpen"), index + 1 < args.count,
              let number = Int(args[index + 1]), (1...8).contains(number) else { return [] }
        return [.memory(id(number))]
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
            for memory in memories(photoStore: photoStore) { try? repository.add(memory) }
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "en_US")
        return HomeViewModel(repository: repository, photoStore: photoStore, calendar: calendar, now: { now })
    }

    // Force unwraps are intended: compile-time UUID literals (notes/sample-data.md).
    private static func id(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "F1000000-0000-0000-0000-%012d", n))!
    }

    private static func memories(photoStore: PhotoStore) -> [Memory] {
        func photo(_ n: Int, _ title: String, _ place: String?, hoursAgo: Double, colors: (UInt32, UInt32)) -> Memory {
            let fileName = try? photoStore.save(imageData: gradientJPEG(colors), id: id(n))
            return Memory(id: id(n), kind: .photo, title: title, placeName: place, photoFileName: fileName,
                          createdAt: now.addingTimeInterval(-hoursAgo * 3600))
        }
        func note(_ n: Int, _ title: String, _ body: String?, _ place: String?, hoursAgo: Double) -> Memory {
            Memory(id: id(n), kind: .note, title: title, body: body, placeName: place,
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
