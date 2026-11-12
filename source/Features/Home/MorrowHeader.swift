import SwiftUI

/// Home header (Main.dc.html lines 22-28): empty slot where Search arrives (T-005 step 5),
/// logo in the middle, notification bell and settings gear on the right.
/// The bell's dot is placeholder chrome (see `MorrowPlaceholders`).
struct MorrowHeader: View {
    let onNotifications: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: HomeMetrics.headerButton, height: HomeMetrics.headerButton)
                .accessibilityHidden(true)
            Spacer(minLength: 0)
            MorrowLogo()
            Spacer(minLength: 0)
            HStack(spacing: HomeMetrics.headerButtonGap) {
                CircleIconButton(
                    systemImage: "bell", label: "Notifications",
                    diameter: HomeMetrics.headerButton, action: onNotifications
                )
                .accessibilityHint(MorrowPlaceholders.notificationsHint)
                // PLACEHOLDER (release blocker, see MorrowPlaceholders)
                .overlay(alignment: .topTrailing) {
                    if MorrowPlaceholders.showsNotificationDot { notificationDot }
                }
                CircleIconButton(
                    systemImage: "gearshape", label: "Settings",
                    diameter: HomeMetrics.headerButton, action: onSettings
                )
            }
        }
        .frame(height: HomeMetrics.headerHeight)
    }

    private var notificationDot: some View {
        Circle()
            .fill(MorrowColor.notificationDot)
            .frame(width: HomeMetrics.notificationDot, height: HomeMetrics.notificationDot)
            .background(Circle().fill(MorrowColor.card).padding(-HomeMetrics.notificationDotRing))
            .padding(.top, HomeMetrics.notificationDotTop)
            .padding(.trailing, HomeMetrics.notificationDotTrailing)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview("Header") {
    MorrowHeader(onNotifications: {}, onSettings: {})
        .padding(.horizontal, HomeMetrics.pageSide)
        .background(MorrowColor.ground)
}
