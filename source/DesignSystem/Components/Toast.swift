import SwiftUI

/// Small transient message capsule. Not an alert: it never blocks the user.
struct Toast: View {
    let message: String

    var body: some View {
        Text(message)
            .font(MorrowFont.notice)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(MorrowColor.ink))
            .accessibilityElement(children: .combine)
    }
}
