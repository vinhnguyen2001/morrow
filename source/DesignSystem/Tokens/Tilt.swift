import Foundation

/// Deterministic small rotation per item so cards look hand-placed but never jump between renders.
/// Not `hashValue`: that is randomised per process. FNV-1a over the UUID bytes is stable.
enum Tilt {
    static func degrees(for id: UUID, maxDegrees: Double = 2) -> Double {
        let hash = withUnsafeBytes(of: id.uuid) { fnv1a($0) }
        let unit = Double(hash % 2001) / 1000.0 - 1.0 // -1...1
        return unit * maxDegrees
    }

    /// FNV-1a 64-bit. Internal so tests can pin it against published vectors.
    static func fnv1a<S: Sequence>(_ bytes: S) -> UInt64 where S.Element == UInt8 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in bytes {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return hash
    }
}
