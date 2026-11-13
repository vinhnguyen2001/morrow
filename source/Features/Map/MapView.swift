import MapKit
import SwiftUI

/// Map of memories that have a coordinate (T-004 step 4, ADR 0009). Reads `model.memories`, never fetches.
/// MapKit draws the map without any permission; this screen never asks for or shows the user's location.
/// A pin opens a peek sheet; pulling it up (or tapping the row) shows the one `MemoryDetailView`.
struct MapView: View {
    let model: HomeViewModel
    @State private var pins: [MapPin]
    @State private var position: MapCameraPosition
    @State private var selection: UUID?
    @State private var detent: PresentationDetent = Self.peek
    /// Latest region the camera settled on (`.onEnd` only: continuous updates would re-render on every pan frame).
    @State private var visibleRegion: MapRegion?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static let peek = PresentationDetent.height(MapMetrics.peekHeight)

    init(model: HomeViewModel) {
        self.model = model
        let initial = MapPins.pins(from: model.memories)
        _pins = State(initialValue: initial)
        _position = State(initialValue: .region(MapFraming.region(for: initial).mapRegion))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                map
                CircleIconButton(systemImage: "chevron.left", label: "Back", diameter: MapMetrics.backButton) { back() }
                    .padding(.leading, DetailMetrics.backSide)
                    .padding(.top, DetailMetrics.backTopBelowStatusBar)
                if model.hasLoaded && pins.isEmpty { emptyOverlay }
            }
            .onChange(of: selection) { _, id in
                if let id { center(on: id, mapHeight: proxy.size.height) } else { detent = Self.peek }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: model.memories, initial: true) { _, memories in
            let updated = MapPins.pins(from: memories)
            guard updated != pins else { return }
            // The first memories can arrive after the screen opens: frame them once, never fight a later pan.
            if pins.isEmpty { position = .region(MapFraming.region(for: updated).mapRegion) }
            pins = updated
            // A memory deleted while its peek is open closes the sheet.
            selection = MapPins.validSelection(selection, in: updated)
        }
        .sheet(isPresented: sheetBinding) { sheet }
        #if DEBUG
        // Screenshot fixtures: select a pin once the screen is on show (a sheet presented mid-push can fail).
        .task {
            guard let id = LaunchFixtures.mapSelection else { return }
            try? await Task.sleep(for: .seconds(1))
            selection = id
            if LaunchFixtures.mapLarge { detent = .large }
        }
        #endif
    }

    private var map: some View {
        Map(position: $position, selection: $selection) {
            ForEach(pins) { pin in
                Marker(pin.title, systemImage: MemoryKindStyle.style(for: pin.kind).symbolName,
                       coordinate: pin.coordinate.mapCoordinate)
                    .tint(MorrowColor.action)
                    .tag(pin.id)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .onMapCameraChange(frequency: .onEnd) { context in visibleRegion = MapRegion(context.region) }
        .ignoresSafeArea()
    }

    private var emptyOverlay: some View {
        VStack(spacing: 6) {
            Text("No memories with a location yet")
                .font(MorrowFont.rowTitle)
                .foregroundStyle(MorrowColor.ink)
            Text("Memories you save with your location on appear here.")
                .font(MorrowFont.rowDetail)
                .foregroundStyle(MorrowColor.textSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(RoundedRectangle(cornerRadius: MapMetrics.rowRadius, style: .continuous).fill(MorrowColor.card))
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: Sheet

    /// One sheet whose content follows `selection`: tapping another pin swaps the row instead of re-presenting
    /// (`sheet(item:)` would flash). Swiping the sheet down clears the selection.
    private var sheetBinding: Binding<Bool> {
        Binding(get: { selection != nil }, set: { if !$0 { selection = nil } })
    }

    private var sheet: some View {
        sheetContent
            .presentationDetents([Self.peek, .large], selection: $detent)
            .presentationBackgroundInteraction(.enabled(upThrough: Self.peek))
            .presentationDragIndicator(.visible)
            .presentationBackground(MorrowColor.ground)
            .presentationCornerRadius(MapMetrics.sheetCorner)
    }

    @ViewBuilder
    private var sheetContent: some View {
        if let id = selection {
            if detent == .large {
                // Built only when expanded, so the peek stays light.
                MemoryDetailView(id: id, model: model, showsBackButton: false)
            } else if let memory = model.memory(id: id) {
                VStack(spacing: MapMetrics.hintTop) {
                    MapPeekRow(memory: memory) { detent = .large }
                        .padding(.horizontal, MapMetrics.rowSide)
                        .padding(.top, MapMetrics.rowTop)
                    if !dynamicTypeSize.isAccessibilitySize {
                        Text("pull up to read · pull down to close")
                            .font(MorrowFont.notice)
                            .foregroundStyle(MorrowColor.textSecondary)
                            .accessibilityHidden(true)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: Actions

    private func back() {
        selection = nil
        dismiss()
    }

    /// Slides the camera so the pin sits above the peek sheet. Reduce Motion: jump without animation.
    private func center(on id: UUID, mapHeight: CGFloat) {
        guard let pin = pins.first(where: { $0.id == id }), mapHeight > 0 else { return }
        let current = visibleRegion ?? MapFraming.region(for: pins)
        let target = MapFraming.region(centering: pin.coordinate, keeping: current,
                                       coveredBottomFraction: Double(MapMetrics.peekHeight / mapHeight))
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
            position = .region(target.mapRegion)
        }
    }
}

private extension Coordinate {
    var mapCoordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}

private extension MapRegion {
    init(_ region: MKCoordinateRegion) {
        self.init(centerLatitude: region.center.latitude, centerLongitude: region.center.longitude,
                  latitudeSpan: region.span.latitudeDelta, longitudeSpan: region.span.longitudeDelta)
    }

    var mapRegion: MKCoordinateRegion {
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude),
                           span: MKCoordinateSpan(latitudeDelta: latitudeSpan, longitudeDelta: longitudeSpan))
    }
}
