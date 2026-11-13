import Foundation

/// Items dealt into two columns by display position (0, 2, 4 left; 1, 3, 5 right), like the design's
/// `filter(k % 2)`. `all` keeps display order for the single-column layout. Built once in the projection.
struct TwoColumns<Item: Equatable>: Equatable {
    let all: [Item]
    let left: [Item]
    let right: [Item]

    init(_ items: [Item]) {
        all = items
        left = items.enumerated().filter { $0.offset.isMultiple(of: 2) }.map(\.element)
        right = items.enumerated().filter { !$0.offset.isMultiple(of: 2) }.map(\.element)
    }

    static var empty: TwoColumns { TwoColumns([]) }
    var isEmpty: Bool { all.isEmpty }
}
