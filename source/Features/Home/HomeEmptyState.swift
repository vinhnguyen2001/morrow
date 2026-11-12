import SwiftUI

/// Shown when there are no memories (Main.dc.html lines 48-56). The "see what travelers left nearby"
/// link is not built: public discovery is deferred (ADR 0010).
struct HomeEmptyState: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: HomeMetrics.emptyGap) {
            GardenIllustration()
            Text("Your garden is waiting")
                .font(MorrowFont.emptyTitle)
                .tracking(-0.3)
                .foregroundStyle(MorrowColor.ink)
                .accessibilityAddTraits(.isHeader)
            Text("Leave your first moment, a photo or a note. Each one grows into a timeline here.")
                .font(MorrowFont.body)
                .foregroundStyle(MorrowColor.textSecondary)
                .lineSpacing(3)
            Text("Leave a moment. Discover a story.")
                .font(MorrowFont.tagline)
                .foregroundStyle(MorrowColor.action)
            Button(action: onAdd) {
                Label("Plant your first memory", systemImage: "plus")
                    .font(MorrowFont.cta)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 26)
                    .frame(minHeight: HomeMetrics.ctaHeight)
                    .background(Capsule().fill(MorrowColor.action))
                    .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, HomeMetrics.emptyInset)
        .padding(.top, HomeMetrics.emptyTop)
        .frame(maxWidth: .infinity)
    }
}

#Preview("Empty") {
    ScrollView { HomeEmptyState(onAdd: {}) }.background(GroundView())
}
