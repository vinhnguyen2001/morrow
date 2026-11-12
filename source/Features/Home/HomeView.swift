import SwiftUI

/// M2 Home: own memories, newest first, Add button. Map button arrives with M3.
struct HomeView: View {
    @State var model: HomeViewModel
    @State private var showCapture = false
    @State private var pendingDelete: Memory?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// One column at accessibility text sizes so titles are not squeezed.
    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 14), count: count)
    }

    var body: some View {
        ZStack {
            GroundView()
            VStack(spacing: 0) {
                header
                if model.memories.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
        }
        .environment(\.photoStore, model.photoStore)
        .task { model.load() }
        .sheet(isPresented: $showCapture) {
            CaptureSheet(model: model.makeCapture()) {
                model.load()
            }
        }
        .deleteConfirmation(for: $pendingDelete) { memory in
            Task { await model.delete(memory) }
        }
    }

    private var header: some View {
        HStack {
            Text("Morrow")
                .font(.system(.largeTitle, weight: .heavy))
                .foregroundStyle(MorrowColor.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            CircleIconButton(systemImage: "plus", label: "Add memory", prominent: true) {
                showCapture = true
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var list: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(model.memories) { memory in
                    MemoryCard(memory: memory, density: .compact)
                        .tilt(for: memory.id)
                        .contextMenu {
                            Button("Delete", systemImage: "trash", role: .destructive) { pendingDelete = memory }
                        }
                        .accessibilityAction(named: "Delete") { pendingDelete = memory }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            if let message = model.errorMessage {
                Text(message).font(MorrowFont.caption).foregroundStyle(MorrowColor.error)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Text("No memories yet")
                .font(.system(.title3, weight: .heavy))
                .foregroundStyle(MorrowColor.ink)
            Text("Tap + to save a photo or a note.")
                .font(MorrowFont.body)
                .foregroundStyle(MorrowColor.textSecondary)
            if let message = model.errorMessage {
                Text(message).font(MorrowFont.caption).foregroundStyle(MorrowColor.error)
            }
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .accessibilityElement(children: .combine)
    }
}
