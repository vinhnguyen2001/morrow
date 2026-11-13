import PhotosUI
import SwiftUI
import UIKit

/// One-step capture: photo or note, title, optional place. Private and local by default.
struct CaptureSheet: View {
    @State var model: CaptureViewModel
    var onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var pickerItem: PhotosPickerItem?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ZStack {
                GroundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if let message = model.errorMessage {
                            Text(message).font(MorrowFont.caption).foregroundStyle(MorrowColor.error)
                        }
                        kindPicker
                        if model.kind == .photo { photoSection } else { noteSection }
                        field("Title", text: $model.title)
                            .limitedLength($model.title, to: Memory.Limits.title)
                        field(placePlaceholder, text: placeBinding)
                            .limitedLength(placeBinding, to: Memory.Limits.place)
                        locationLine
                        Label("Saved on this device. Private.", systemImage: "lock")
                            .font(MorrowFont.caption)
                            .foregroundStyle(MorrowColor.textSecondary)
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(model.isSaving) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await model.save() {
                                onSaved()
                                dismiss()
                            }
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(!model.canSave)
                }
            }
        }
        .tint(MorrowColor.action)
        .interactiveDismissDisabled(model.isSaving)
        // `.task(id:)` cancels the previous load when the selection changes.
        .task(id: pickerItem) {
            let data = try? await pickerItem?.loadTransferable(type: Data.self)
            guard !Task.isCancelled else { return }
            await model.setPhoto(data)
        }
        // Not tied to pickerItem; cancelled when the sheet goes away, and by Save.
        .task { await model.startLocating() }
        // The user may have changed the permission in Settings while the sheet was open.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await model.recheckAuthorization() } }
        }
        .onChange(of: model.errorMessage) { _, message in
            if let message { AccessibilityNotification.Announcement(message).post() }
        }
    }

    /// Typing marks the place as the user's own, so a late suggestion never overwrites it.
    private var placeBinding: Binding<String> {
        Binding(get: { model.placeName }, set: { model.setPlaceName(byUser: $0) })
    }

    private var placePlaceholder: String {
        model.locationState == .locating || model.isFindingPlace ? "Finding your place\u{2026}" : "Place (optional)"
    }

    /// One quiet line under Place: nothing while looking, the pin and a remove button when found, the reason when not.
    @ViewBuilder private var locationLine: some View {
        switch model.locationState {
        case .idle, .locating:
            EmptyView()
        case .located:
            HStack(spacing: 4) {
                Label("Pinned to your location", systemImage: "location.fill")
                    .font(MorrowFont.caption)
                    .foregroundStyle(MorrowColor.textSecondary)
                Spacer(minLength: 0)
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { model.clearLocation() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(MorrowColor.textSecondary)
                        .frame(width: MorrowLayout.minHitSize, height: MorrowLayout.minHitSize)
                }
                .accessibilityLabel("Remove location")
            }
        case .unavailable:
            HStack(spacing: 6) {
                Label(unavailableText, systemImage: "location.slash")
                    .font(MorrowFont.caption)
                    .foregroundStyle(MorrowColor.textSecondary)
                if model.offersSettingsLink {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                    .font(MorrowFont.caption)
                }
            }
        }
    }

    private var unavailableText: String {
        switch model.authorization {
        case .denied: return "Location is off. You can still save."
        case .restricted: return "Location isn't available on this device."
        case .notDetermined, .authorized: return "Couldn't find your location. You can still save."
        }
    }

    private var kindPicker: some View {
        Picker("Kind", selection: $model.kind) {
            ForEach(MemoryKind.allCases, id: \.self) { kind in
                Text(MemoryKindStyle.style(for: kind).displayName).tag(kind)
            }
        }
        .pickerStyle(.segmented)
    }

    private var photoSection: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            ZStack {
                MorrowColor.card
                if let data = model.photoPreview, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Label("Choose a photo", systemImage: "photo.on.rectangle")
                        .font(MorrowFont.actionLabel)
                        .foregroundStyle(MorrowColor.ink)
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: MorrowRadius.cardImage, style: .continuous))
            .morrowCardShadow()
        }
        .accessibilityLabel(model.photoPreview == nil ? "Choose a photo" : "Change photo")
    }

    private var noteSection: some View {
        TextField("Write something to remember", text: $model.body, axis: .vertical)
            .lineLimit(5...10)
            .font(MorrowFont.body)
            .padding(14)
            .background(MorrowColor.card, in: RoundedRectangle(cornerRadius: MorrowRadius.cardImage, style: .continuous))
            .limitedLength($model.body, to: Memory.Limits.body)
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .font(MorrowFont.body)
            .padding(14)
            .background(MorrowColor.card, in: RoundedRectangle(cornerRadius: MorrowRadius.cardImage, style: .continuous))
    }
}
