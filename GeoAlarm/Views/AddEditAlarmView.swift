// MARK: - File: GeoAlarm/Views/AddEditAlarmView.swift
// ═══════════════════════════════════════════════════════════════════════════════
//  GeoAlarm — Location-Based Alarm App (Swift Student Challenge)
//
//  AddEditAlarmView provides a Form-based interface for creating or editing
//  a location alarm.
//
//  Design refinements:
//    • Section headers use appSectionHeader font + appPrimary tint on icons.
//    • The Save button uses AppPrimaryButtonStyle (deep canopy green).
//    • Cancel uses the tinted system style (inherits appPrimary from tint).
//    • Form background tinted with appBackground for cohesion.
//    • Radius picker and Trigger picker use themed accents.
// ═══════════════════════════════════════════════════════════════════════════════

import SwiftUI
import MapKit

// MARK: - ViewMode

/// Whether we are adding a new alarm or editing an existing one.
enum AlarmViewMode {
    case add
    case edit(GeoAlarm)
}

struct AddEditAlarmView: View {

    // MARK: Environment

    @EnvironmentObject var alarmStore: GeoAlarmStore
    @Environment(\.dismiss) private var dismiss

    // MARK: Init

    let mode: AlarmViewMode

    // MARK: Form State

    @State private var title: String = ""
    @State private var triggerType: TriggerType = .onArrival
    @State private var selectedPreset: PresetLocation? = PresetLocation.presets[0]
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    @State private var locationName: String = ""
    @State private var selectedRadius: Double = 250
    @State private var usePreset: Bool = true

    /// Map camera position for the preview.
    @State private var mapPosition: MapCameraPosition = .automatic

    // MARK: Derived

    /// The alarm ID if editing; nil if adding.
    private var existingAlarmID: UUID? {
        if case .edit(let alarm) = mode { return alarm.id }
        return nil
    }

    /// The effective coordinate based on preset or manual input.
    private var effectiveCoordinate: CLLocationCoordinate2D {
        if usePreset, let preset = selectedPreset {
            return preset.coordinate
        }
        return CLLocationCoordinate2D(
            latitude: Double(latitude) ?? 0,
            longitude: Double(longitude) ?? 0
        )
    }

    /// Whether the form has enough data to save.
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            Form {
                // ── Section 1: Title ──────────────────────────────────
                Section {
                    TextField("Alarm title", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .font(.appBody)
                } header: {
                    Label("Title", systemImage: "pencil")
                        .foregroundStyle(Color.appPrimary)
                } footer: {
                    Text("e.g., \"Text Mom at school\" or \"Buy milk\"")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }

                // ── Section 2: Trigger Type ──────────────────────────
                Section {
                    Picker("Trigger", selection: $triggerType) {
                        ForEach(TriggerType.allCases) { type in
                            Label(type.rawValue, systemImage: type.sfSymbol)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Label("When to Trigger", systemImage: "bell")
                        .foregroundStyle(Color.appPrimary)
                }

                // ── Section 3: Location ──────────────────────────────
                Section {
                    Toggle("Use Preset Location", isOn: $usePreset)
                        .tint(Color.appPrimary)

                    if usePreset {
                        // Preset picker
                        Picker("Location", selection: $selectedPreset) {
                            ForEach(PresetLocation.presets) { preset in
                                Label(preset.name, systemImage: preset.sfSymbol)
                                    .tag(Optional(preset))
                            }
                        }
                    } else {
                        // Manual coordinate entry
                        TextField("Location Name", text: $locationName)
                            .font(.appBody)
                        TextField("Latitude", text: $latitude)
                            .keyboardType(.decimalPad)
                            .font(.appMono)
                        TextField("Longitude", text: $longitude)
                            .keyboardType(.decimalPad)
                            .font(.appMono)
                    }
                } header: {
                    Label("Location", systemImage: "mappin")
                        .foregroundStyle(Color.appPrimary)
                } footer: {
                    Text("Choose a preset for quick setup, or enter exact coordinates.")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }

                // ── Section 4: Radius ────────────────────────────────
                Section {
                    Picker("Radius", selection: $selectedRadius) {
                        ForEach(RadiusOption.options) { option in
                            Text(option.label).tag(option.meters)
                        }
                    }
                } header: {
                    Label("Detection Radius", systemImage: "circle.dashed")
                        .foregroundStyle(Color.appPrimary)
                }

                // ── Section 5: Map Preview ───────────────────────────
                Section {
                    MapPickerView(
                        coordinate: effectiveCoordinate,
                        radius: selectedRadius
                    )
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                } header: {
                    Label("Preview", systemImage: "map")
                        .foregroundStyle(Color.appPrimary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle(existingAlarmID != nil ? "Edit Alarm" : "New Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.appTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAlarm() }
                        .disabled(!canSave)
                        .bold()
                        .foregroundStyle(canSave ? Color.appPrimary : Color.appTextSecondary.opacity(0.4))
                }
            }
            .onAppear { prepopulateIfEditing() }
        }
    }

    // MARK: - Actions

    /// Saves (or updates) the alarm and dismisses the sheet.
    private func saveAlarm() {
        let name: String
        if usePreset, let preset = selectedPreset {
            name = preset.name
        } else {
            name = locationName.isEmpty
                ? String(format: "%.4f, %.4f", effectiveCoordinate.latitude, effectiveCoordinate.longitude)
                : locationName
        }

        let alarm = GeoAlarm(
            id: existingAlarmID ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            triggerType: triggerType,
            latitude: effectiveCoordinate.latitude,
            longitude: effectiveCoordinate.longitude,
            radius: selectedRadius,
            locationName: name
        )

        if existingAlarmID != nil {
            alarmStore.updateAlarm(alarm)
        } else {
            alarmStore.addAlarm(alarm)
        }

        dismiss()
    }

    /// Pre-fills form fields when editing an existing alarm.
    private func prepopulateIfEditing() {
        guard case .edit(let alarm) = mode else { return }
        title = alarm.title
        triggerType = alarm.triggerType
        selectedRadius = alarm.radius
        locationName = alarm.locationName

        // Check if the alarm location matches a preset.
        if let matched = PresetLocation.presets.first(where: {
            $0.latitude == alarm.latitude && $0.longitude == alarm.longitude
        }) {
            usePreset = true
            selectedPreset = matched
        } else {
            usePreset = false
            latitude = String(alarm.latitude)
            longitude = String(alarm.longitude)
        }
    }
}
