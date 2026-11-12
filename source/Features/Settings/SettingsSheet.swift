import SwiftUI

/// Minimal real Settings (T-005): version and where data lives. More arrives with accounts (M6).
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String
        return build.map { "\(version) (\($0))" } ?? version
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Version", value: versionText)
                } footer: {
                    Text("Your memories are stored on this device")
                        .font(MorrowFont.caption)
                }
            }
            .font(MorrowFont.body)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview("Settings") {
    SettingsSheet()
}
