import SwiftUI

/// Bottom floating buttons (Main.dc.html lines 206-208): white Map button on the left (56pt), Add on the right
/// (64pt, action colour, no rotation), both bottom-aligned. Positioned from the screen edge, not the safe area,
/// as in the design.
struct FloatingActionBar: View {
    let onMap: () -> Void
    let onAdd: () -> Void

    var body: some View {
        HStack(alignment: .bottom) {
            mapButton
            Spacer()
            CircleIconButton(
                systemImage: "plus", label: "Add memory", prominent: true,
                diameter: HomeMetrics.addButton, iconFont: MorrowFont.iconLarge, action: onAdd
            )
        }
        .padding(.horizontal, HomeMetrics.fabSideInset)
        .padding(.bottom, HomeMetrics.fabBottomInset)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(edges: .bottom)
    }

    private var mapButton: some View {
        CircleIconButton(systemImage: "map", label: "Map", diameter: HomeMetrics.mapButton, action: onMap)
            .overlay(alignment: .topTrailing) {
                if MorrowPlaceholders.showsNearbyBadge { badge }
            }
    }

    /// PLACEHOLDER (MorrowPlaceholders, release blocker): a fixed number, hidden from VoiceOver and from touches.
    private var badge: some View {
        Text("\(MorrowPlaceholders.nearbyCount)")
            .font(MorrowFont.micro)
            .foregroundStyle(Color.white)
            .padding(.horizontal, 5)
            .frame(minWidth: HomeMetrics.mapBadge, minHeight: HomeMetrics.mapBadge)
            .background(Capsule().fill(MorrowColor.action))
            .padding(HomeMetrics.mapBadgeRing) // white ring drawn outside the badge, like the design's box-shadow
            .background(Capsule().fill(MorrowColor.card))
            .offset(x: HomeMetrics.mapBadgeOffset, y: -HomeMetrics.mapBadgeOffset)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
