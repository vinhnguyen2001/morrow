import PhotosUI
import SwiftUI
import UIKit

/// One-step capture: photo or note, title, optional place. Private and local by default.
struct CaptureSheet: View {
    @State var model: CaptureViewModel
    var onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                GroundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        kindPicker
                        if model.kind == .photo { photoSection } else { noteSection }
                        field("Title", text: $model.title)
                        field("Place (optional)", text: $model.placeName)
                        Label("Saved on this device. Private.", systemImage: "lock")
                            .font(MorrowFont.caption)
                            .foregroundStyle(MorrowColor.textSecondary)
                        if let message = model.errorMessage {
                            Text(message).font(MorrowFont.caption).foregroundStyle(.red)
                        }
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
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
        .onChange(of: pickerItem) { _, item in
            Task { await model.setPhoto(try? await item?.loadTransferable(type: Data.self)) }
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
                        .font(.system(.subheadline, weight: .bold))
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
            .onChange(of: model.body) { _, text in
                if text.count > CaptureViewModel.maxBody { model.body = String(text.prefix(CaptureViewModel.maxBody)) }
            }
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .font(MorrowFont.body)
            .padding(14)
            .background(MorrowColor.card, in: RoundedRectangle(cornerRadius: MorrowRadius.cardImage, style: .continuous))
    }
}
