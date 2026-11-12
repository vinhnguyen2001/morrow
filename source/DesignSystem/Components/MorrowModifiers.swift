import SwiftUI

extension View {
    /// Card shadow: 0 1px 2px black 6% plus a soft lift.
    /// SwiftUI has no spread, so the second layer approximates CSS `0 14px 30px -12px black 35%`.
    func morrowCardShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.06), radius: 1, x: 0, y: 1)
            .shadow(color: .black.opacity(0.30), radius: 12, x: 0, y: 12)
    }

    /// Small rotation, stable for a given item ID. Disabled under Reduce Motion.
    func tilt(for id: UUID, maxDegrees: Double = 2) -> some View {
        tilt(degrees: Tilt.degrees(for: id, maxDegrees: maxDegrees))
    }

    /// Rotation by a given angle. Disabled under Reduce Motion.
    func tilt(degrees: Double) -> some View {
        modifier(TiltModifier(degrees: degrees))
    }
}

struct TiltModifier: ViewModifier {
    let degrees: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.rotationEffect(.degrees(reduceMotion ? 0 : degrees))
    }
}
