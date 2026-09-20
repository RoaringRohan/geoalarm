// MARK: - File: GeoAlarm/Views/SimulationControlView.swift
// ═══════════════════════════════════════════════════════════════════════════════
//  GeoAlarm — Location-Based Alarm App (Swift Student Challenge)
//
//  SimulationControlView lets the user manipulate the simulated "current
//  location" when the app is running in Simulation Mode.
//
//  Design refinements:
//    • appBackground on the list surface for palette cohesion.
//    • Section headers tinted with appPrimary icons.
//    • Current position readout uses appAccent (amber) for the location icon
//      since this is a simulation-specific view.
//    • Coordinate text uses appMono for aligned digit display.
//    • Preset buttons use appSecondary tint.
//    • Walk slider uses appPrimary tint.
//    • Live map pins use appPrimary and appAccent to match the palette.
// ═══════════════════════════════════════════════════════════════════════════════

import SwiftUI
import MapKit

struct SimulationControlView: View {

    // MARK: Environment

    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var alarmStore: GeoAlarmStore
    @Environment(\.dismiss) private var dismiss

    // MARK: State

    /// Manual coordinate text fields.
    @State private var latText: String = ""
    @State private var lonText: String = ""

    /// The alarm selected for the "walk toward" slider.
    @State private var walkTargetAlarm: GeoAlarm?

    /// Slider value: 0 = current position, 1 = at the alarm center.
    @State private var walkProgress: Double = 0

    /// The position the walk started from (captured when user selects a target).
    @State private var walkStartCoordinate: SimpleCoordinate?

    // MARK: Body

    var body: some View {
        NavigationStack {
            List {
                // ── Current Simulated Position ───────────────────────
                Section {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(Color.appAccent)
                        VStack(alignment: .leading) {
                            Text("Simulated Position")
                                .font(.appCaption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.appTextSecondary)
                            Text(coordinateString(locationManager.simulatedLocation))
                                .font(.appMono)
                                .foregroundStyle(Color.appTextPrimary)
                        }
                    }
                } header: {
                    Label("Current Position", systemImage: "scope")
                        .foregroundStyle(Color.appPrimary)
                }

                // ── Preset Locations ─────────────────────────────────
                Section {
                    ForEach(PresetLocation.presets) { preset in
                        Button {
                            locationManager.updateSimulatedLocation(preset.coordinate)
                            latText = String(preset.latitude)
                            lonText = String(preset.longitude)
                            walkProgress = 0
                        } label: {
                            Label(preset.name, systemImage: preset.sfSymbol)
                                .foregroundStyle(Color.appSecondary)
                        }
                    }
                } header: {
                    Label("Teleport to Preset", systemImage: "arrow.triangle.swap")
                        .foregroundStyle(Color.appPrimary)
                } footer: {
                    Text("Tap a preset to instantly move to that location.")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }

                // ── Manual Coordinates ───────────────────────────────
                Section {
                    TextField("Latitude", text: $latText)
                        .keyboardType(.decimalPad)
                        .font(.appMono)
                    TextField("Longitude", text: $lonText)
                        .keyboardType(.decimalPad)
                        .font(.appMono)
                    Button("Apply") {
                        if let lat = Double(latText), let lon = Double(lonText) {
                            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                            locationManager.updateSimulatedLocation(coord)
                            walkProgress = 0
                        }
                    }
                    .foregroundStyle(Color.appPrimary)
                    .disabled(Double(latText) == nil || Double(lonText) == nil)
                } header: {
                    Label("Manual Entry", systemImage: "number")
                        .foregroundStyle(Color.appPrimary)
                }

                // ── Walk Toward Alarm ────────────────────────────────
                if !alarmStore.alarms.isEmpty {
                    Section {
                        Picker("Target Alarm", selection: $walkTargetAlarm) {
                            Text("None").tag(GeoAlarm?.none)
                            ForEach(alarmStore.alarms) { alarm in
                                Text(alarm.title).tag(Optional(alarm))
                            }
                        }
                        .onChange(of: walkTargetAlarm) { _, _ in
                            // Capture the start position when selecting a target.
                            walkStartCoordinate = SimpleCoordinate(
                                latitude: locationManager.simulatedLocation.latitude,
                                longitude: locationManager.simulatedLocation.longitude
                            )
                            walkProgress = 0
                        }

                        if let target = walkTargetAlarm, let start = walkStartCoordinate {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Distance: \(distanceLabel(to: target))")
                                    .font(.appCaption)
                                    .foregroundStyle(Color.appTextSecondary)

                                Slider(value: $walkProgress, in: 0...1, step: 0.01) {
                                    Text("Walk")
                                } minimumValueLabel: {
                                    Image(systemName: "figure.stand")
                                        .foregroundStyle(Color.appSecondary)
                                } maximumValueLabel: {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(Color.appPrimary)
                                }
                                .tint(Color.appPrimary)
                                .onChange(of: walkProgress) { _, newValue in
                                    let dest = SimpleCoordinate(
                                        latitude: target.latitude,
                                        longitude: target.longitude
                                    )
                                    let interp = GeoAlarmEngine.interpolate(
                                        from: start,
                                        to: dest,
                                        t: newValue
                                    )
                                    let coord = CLLocationCoordinate2D(
                                        latitude: interp.latitude,
                                        longitude: interp.longitude
                                    )
                                    locationManager.updateSimulatedLocation(coord)
                                }
                            }
                        }
                    } header: {
                        Label("Walk Toward Alarm", systemImage: "figure.walk")
                            .foregroundStyle(Color.appPrimary)
                    } footer: {
                        Text("Select an alarm and drag the slider to simulate walking toward it. The alarm will trigger when you enter its radius.")
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }

                // ── Live Map ─────────────────────────────────────────
                Section {
                    liveMap
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                } header: {
                    Label("Live Map", systemImage: "map")
                        .foregroundStyle(Color.appPrimary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Simulation Controls")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.appPrimary)
                }
            }
            .onAppear {
                latText = String(format: "%.6f", locationManager.simulatedLocation.latitude)
                lonText = String(format: "%.6f", locationManager.simulatedLocation.longitude)
            }
        }
    }

    // MARK: - Live Map

    /// Shows the simulated position and all alarm regions on a map.
    /// Markers and circles use the design-system palette.
    private var liveMap: some View {
        let simLoc = locationManager.simulatedLocation
        let region = MKCoordinateRegion(
            center: simLoc,
            latitudinalMeters: 2000,
            longitudinalMeters: 2000
        )

        return Map(initialPosition: .region(region)) {
            // Simulated position marker — teal (appSecondary)
            Annotation("You (Simulated)", coordinate: simLoc) {
                ZStack {
                    Circle()
                        .fill(Color.appSecondary.opacity(0.3))
                        .frame(width: 28, height: 28)
                    Image(systemName: "figure.walk.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.appSecondary)
                }
            }

            // All alarm regions — appPrimary pins and circles
            ForEach(alarmStore.alarms) { alarm in
                Annotation(alarm.title, coordinate: alarm.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.appPrimary)
                }

                MapCircle(center: alarm.coordinate, radius: alarm.radius)
                    .foregroundStyle(Color.appPrimary.opacity(0.10))
                    .stroke(Color.appPrimary.opacity(0.35), lineWidth: 1.5)
            }
        }
        .mapStyle(.standard(elevation: .flat))
    }

    // MARK: - Helpers

    private func coordinateString(_ coord: CLLocationCoordinate2D) -> String {
        String(format: "%.6f, %.6f", coord.latitude, coord.longitude)
    }

    private func distanceLabel(to alarm: GeoAlarm) -> String {
        let from = SimpleCoordinate(
            latitude: locationManager.simulatedLocation.latitude,
            longitude: locationManager.simulatedLocation.longitude
        )
        let to = SimpleCoordinate(latitude: alarm.latitude, longitude: alarm.longitude)
        let dist = GeoAlarmEngine.haversineDistance(from: from, to: to)
        if dist >= 1000 {
            return String(format: "%.1f km", dist / 1000)
        }
        return String(format: "%.0f m", dist)
    }
}
