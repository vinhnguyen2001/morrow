import Foundation

/// Hand-placed look of one timeline row: side, tilt, vertical offset, photo height, leaf.
/// The index counts from the OLDEST memory (0), so adding a newer memory never moves an old row.
/// The design counts from the top (Main.dc.html lines 1085-1086 and 118-128); that would flip every row on each add.
struct Stagger: Equatable {
    /// Main.dc.html line 1085-1086.
    static let tilts: [Double] = [-3, 2.4, -2.2, 3]
    static let offsets: [CGFloat] = [0, 18, 6]
    /// Decorative rhythm: every third photo is taller (design `tall`).
    static let tallImageHeight: CGFloat = 150
    static let imageHeight: CGFloat = 116

    let isLeft: Bool
    let tilt: Double
    let offset: CGFloat
    let imageHeight: CGFloat
    /// Leaf position down the row as a fraction (design: 52% + (i*17 mod 30)%).
    let leafFraction: CGFloat
    let leafRotation: Double
    let leafIsLight: Bool

    init(index: Int) {
        isLeft = index % 2 == 0
        tilt = Self.tilts[index % Self.tilts.count]
        offset = Self.offsets[index % Self.offsets.count]
        imageHeight = index % 3 == 0 ? Self.tallImageHeight : Self.imageHeight
        leafFraction = CGFloat(52 + (index * 17) % 30) / 100
        leafRotation = isLeft ? 10 : 260
        leafIsLight = index % 2 == 1
    }
}
