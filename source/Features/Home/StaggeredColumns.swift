import SwiftUI

/// Two lazy columns, the second one pushed down (Notes 26pt, Places 30pt), like the design's `padding-top`.
/// Not a `LazyVGrid`: a grid would line the rows up. At accessibility sizes it is one lazy column.
struct StaggeredColumns<Item: Identifiable & Equatable, Tile: View>: View {
    let columns: TwoColumns<Item>
    let layout: TimelineLayout
    let rightColumnOffset: CGFloat
    let rowSpacing: CGFloat
    @ViewBuilder let tile: (Item) -> Tile

    var body: some View {
        switch layout {
        case .twoColumn:
            HStack(alignment: .top, spacing: HomeMetrics.columnGap) {
                column(columns.left)
                column(columns.right).padding(.top, rightColumnOffset)
            }
        case .singleColumn:
            column(columns.all)
        }
    }

    private func column(_ items: [Item]) -> some View {
        LazyVStack(spacing: rowSpacing) {
            ForEach(items) { tile($0) }
        }
        .frame(maxWidth: .infinity)
    }
}
