import SwiftUI

extension View {
    /// Confirmation before deleting a memory. Shared by Home and, later, Detail.
    /// Setting `memory` to a value presents the dialog; confirming calls `onConfirm`.
    func deleteConfirmation(for memory: Binding<Memory?>, onConfirm: @escaping (Memory) -> Void) -> some View {
        confirmationDialog(
            "Delete this memory?",
            isPresented: Binding(
                get: { memory.wrappedValue != nil },
                set: { if !$0 { memory.wrappedValue = nil } }
            ),
            titleVisibility: .visible,
            presenting: memory.wrappedValue
        ) { item in
            Button("Delete", role: .destructive) { onConfirm(item) }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("This can't be undone.")
        }
    }
}
