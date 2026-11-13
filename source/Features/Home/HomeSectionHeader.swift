import SwiftUI

/// Title row of a Home tab ("Recent moments", "Notes", "Places you've been") with something at the trailing end.
/// Side by side normally; stacked at accessibility sizes so the title is not squeezed.
struct HomeSectionHeader<Trailing: View>: View {
    let title: String
    let layout: TimelineLayout
    var alignment: VerticalAlignment = .firstTextBaseline
    @ViewBuilder var trailing: Trailing

    var body: some View {
        let titleText = Text(title)
            .font(MorrowFont.sectionTitle)
            .foregroundStyle(MorrowColor.ink)
            .accessibilityAddTraits(.isHeader)
        switch layout {
        case .twoColumn:
            HStack(alignment: alignment) {
                titleText
                Spacer()
                trailing
            }
        case .singleColumn:
            VStack(alignment: .leading, spacing: 2) {
                titleText
                trailing
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
