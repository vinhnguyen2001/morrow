import SwiftUI

/// Home header (Main.dc.html lines 22-28): Search button on the left, logo in the middle (placed by
/// space-between like the design), notification bell and settings gear on the right.
/// The bell's dot is placeholder chrome (see `MorrowPlaceholders`).
struct MorrowHeader: View {
    let isSearchOpen: Bool
    let onSearch: () -> Void
    let onNotifications: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            CircleIconButton(
                systemImage: "magnifyingglass", label: "Search memories",
                diameter: HomeMetrics.headerButton, action: onSearch
            )
            .accessibilityAddTraits(isSearchOpen ? .isSelected : [])
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
    MorrowHeader(isSearchOpen: false, onSearch: {}, onNotifications: {}, onSettings: {})
        .padding(.horizontal, HomeMetrics.pageSide)
        .background(MorrowColor.ground)
}
