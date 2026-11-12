import SwiftUI

/// Dev-only gallery of MemoryCard variants on the Chronicle ground.
struct MemoryCardGallery: View {
    private let memories = Memory.samples
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ZStack {
            GroundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    Text("Compact").font(MorrowFont.caption).foregroundStyle(MorrowColor.textSecondary)
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(memories) { memory in
                            MemoryCard(memory: memory, density: .compact)
                                .tilt(for: memory.id)
                        }
                    }
                    Text("Wide").font(MorrowFont.caption).foregroundStyle(MorrowColor.textSecondary)
                    ForEach(memories) { memory in
                        MemoryCard(memory: memory, density: .wide)
                            .tilt(for: memory.id)
                    }
                }
                .padding(20)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            ForEach(MemoryKind.allCases, id: \.self) { kind in
                let style = MemoryKindStyle.style(for: kind)
                Chip(style.displayName, systemImage: style.symbolName,
                     background: style.background, foreground: style.ink)
            }
            Spacer()
            CircleIconButton(systemImage: "plus", label: "Add memory") {}
        }
    }
}

#Preview("MemoryCard gallery") {
    MemoryCardGallery()
}
