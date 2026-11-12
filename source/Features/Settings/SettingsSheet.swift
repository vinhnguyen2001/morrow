import SwiftUI

/// Minimal real Settings (T-005): version and where data lives. More arrives with accounts (M6).
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        // Empty counts as missing: never show a made-up version.
        let version = (info?["CFBundleShortVersionString"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let build = (info?["CFBundleVersion"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        switch (version, build) {
        case let (version?, build?): return "\(version) (\(build))"
        case let (version?, nil): return version
        default: return "Unknown"
        }
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
