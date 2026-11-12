import SwiftUI

/// Bottom-right Add button (Main.dc.html line 208): 64pt, action colour, no rotation.
/// The Map button joins this bar at T-005 step 7, when it has a destination.
/// Positioned from the screen edge, not the safe area, as in the design.
struct FloatingActionBar: View {
    let onAdd: () -> Void

    var body: some View {
        HStack {
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
}
