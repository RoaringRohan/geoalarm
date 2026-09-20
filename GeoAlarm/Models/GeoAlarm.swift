// MARK: - File: GeoAlarm/Models/GeoAlarm.swift
// ═══════════════════════════════════════════════════════════════════════════════
//  GeoAlarm — Location-Based Alarm App (Swift Student Challenge)
//
//  This file defines the core data models for the app:
//    • TriggerType    — whether the alarm fires on arrival or departure
//    • GeoAlarmStatus — the alarm's current lifecycle state
//    • GeoAlarm       — the main alarm struct
//    • PresetLocation — handy preset coordinates for simulation mode
//
//  Integration:
//    Add this file to your Xcode project's "Models" group.
//    No external dependencies — pure Swift value types.
// ═══════════════════════════════════════════════════════════════════════════════

import Foundation
import CoreLocation   // For CLLocationCoordinate2D convenience, but all logic is pure Swift

// MARK: - TriggerType
/// Determines when a location alarm should fire.
///
/// - `.onArrival`  — triggers when the user **enters** the alarm's region.
/// - `.onDeparture` — triggers when the user **leaves** the alarm's region.
///
/// Stored as a raw `String` so it serializes nicely with `Codable` and
/// renders well in the UI without extra mapping.
enum TriggerType: String, Codable, CaseIterable, Identifiable {
    case onArrival  = "On Arrival"
    case onDeparture = "On Departure"

    var id: String { rawValue }

    /// SF Symbol name matching each trigger type.
    var sfSymbol: String {
        switch self {
        case .onArrival:  return "arrow.down.to.line.compact"
        case .onDeparture: return "arrow.up.from.line"
        }
    }

    /// A short human-readable sentence used in the alarm detail/row.
    var description: String {
        switch self {
        case .onArrival:  return "Triggers when you arrive"
        case .onDeparture: return "Triggers when you leave"
        }
    }
}

// MARK: - GeoAlarmStatus
/// Represents the lifecycle state of a single alarm.
///
/// Values:
/// - `.waiting`          — monitoring, but the condition hasn't been met yet.
/// - `.triggered(Date)`  — the alarm has fired; the associated `Date` records *when*.
/// - `.disabled`         — the user manually turned this alarm off.
///
/// Note: We conform to `Equatable` manually because the associated value on
/// `.triggered` prevents auto-synthesis.
enum GeoAlarmStatus: Codable, Equatable {
    case waiting
    case triggered(Date)
    case disabled

    /// Human-readable label for the UI.
    var label: String {
        switch self {
        case .waiting:              return "Waiting"
        case .triggered(let date):  return "Triggered \(Self.shortFormatter.string(from: date))"
        case .disabled:             return "Disabled"
        }
    }

    /// Short time formatter shared across all status labels.
    private static let shortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    /// Badge color name (matches SwiftUI Color names).
    var colorName: String {
        switch self {
        case .waiting:    return "blue"
        case .triggered:  return "green"
        case .disabled:   return "gray"
        }
    }

    // MARK: Codable
    // Custom coding because of the associated value in `.triggered`.
    private enum CodingKeys: String, CodingKey {
        case type, triggerDate
    }
    private enum StatusType: String, Codable {
        case waiting, triggered, disabled
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .waiting:
            try container.encode(StatusType.waiting, forKey: .type)
        case .triggered(let date):
            try container.encode(StatusType.triggered, forKey: .type)
            try container.encode(date, forKey: .triggerDate)
        case .disabled:
            try container.encode(StatusType.disabled, forKey: .type)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(StatusType.self, forKey: .type)
        switch type {
        case .waiting:
            self = .waiting
        case .triggered:
            let date = try container.decode(Date.self, forKey: .triggerDate)
            self = .triggered(date)
        case .disabled:
            self = .disabled
        }
    }
}

// MARK: - GeoAlarm
/// The primary model for a location-based alarm.
///
/// Each alarm defines:
///   • A human-readable **title** (e.g., "Buy milk at Store").
///   • A **triggerType** that decides whether the alarm fires on entry or exit.
///   • A **latitude / longitude** center point for the monitored region.
///   • A **radius** in meters around that point.
///   • A **locationName** for UI display (optional, defaults to coordinates).
///   • An **isActive** flag the user can toggle.
///   • A **status** tracking the alarm's lifecycle.
///
/// `Identifiable` lets SwiftUI `List` / `ForEach` use it directly.
/// `Codable` enables easy persistence (UserDefaults, JSON file, etc.).
struct GeoAlarm: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var triggerType: TriggerType
    var latitude: Double
    var longitude: Double
    var radius: Double          // meters
    var locationName: String    // e.g., "School", "Grocery Store"
    var isActive: Bool
    var status: GeoAlarmStatus

    /// Convenience: the alarm's center as a `CLLocationCoordinate2D`.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Human-friendly radius string (e.g., "250 m").
    var radiusLabel: String {
        if radius >= 1000 {
            return String(format: "%.1f km", radius / 1000)
        }
        return "\(Int(radius)) m"
    }

    /// Creates a new alarm with sensible defaults.
    ///
    /// - Parameters:
    ///   - title: What the alarm is for.
    ///   - triggerType: Fire on arrival or departure.
    ///   - latitude: Center latitude.
    ///   - longitude: Center longitude.
    ///   - radius: Monitoring radius in meters (default 250).
    ///   - locationName: Friendly name for the location.
    init(
        id: UUID = UUID(),
        title: String,
        triggerType: TriggerType,
        latitude: Double,
        longitude: Double,
        radius: Double = 250,
        locationName: String = "",
        isActive: Bool = true,
        status: GeoAlarmStatus = .waiting
    ) {
        self.id = id
        self.title = title
        self.triggerType = triggerType
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.locationName = locationName.isEmpty
            ? String(format: "%.4f, %.4f", latitude, longitude)
            : locationName
        self.isActive = isActive
        self.status = status
    }
}

// MARK: - PresetLocation
/// A named coordinate used in Simulation Mode for quick alarm placement or
/// quick simulated-position selection.
///
/// The presets are arbitrary but reasonable: a university campus, a grocery
/// chain, an office building, etc. They let a reviewer test the app without
/// typing coordinates.
struct PresetLocation: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let sfSymbol: String        // icon for the UI picker

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // MARK: Presets
    /// A curated list of five preset locations for simulation.
    /// These are all real-ish coordinates in the San Francisco Bay Area
    /// so they look realistic on a map.
    static let presets: [PresetLocation] = [
        PresetLocation(
            name: "Home",
            latitude: 37.7749,
            longitude: -122.4194,
            sfSymbol: "house.fill"
        ),
        PresetLocation(
            name: "School",
            latitude: 37.7855,
            longitude: -122.4064,
            sfSymbol: "graduationcap.fill"
        ),
        PresetLocation(
            name: "Grocery Store",
            latitude: 37.7694,
            longitude: -122.4262,
            sfSymbol: "cart.fill"
        ),
        PresetLocation(
            name: "Office",
            latitude: 37.7900,
            longitude: -122.4010,
            sfSymbol: "building.2.fill"
        ),
        PresetLocation(
            name: "Park",
            latitude: 37.7699,
            longitude: -122.4869,
            sfSymbol: "leaf.fill"
        ),
    ]
}

// MARK: - Radius Options
/// Predefined radius choices shown in the Add/Edit Alarm picker.
/// We store them as `Double` (meters) and provide a label.
struct RadiusOption: Identifiable, Hashable {
    let id = UUID()
    let meters: Double
    let label: String

    static let options: [RadiusOption] = [
        RadiusOption(meters: 100,  label: "100 m — Very close"),
        RadiusOption(meters: 250,  label: "250 m — Nearby"),
        RadiusOption(meters: 500,  label: "500 m — A few blocks"),
        RadiusOption(meters: 1000, label: "1 km — Neighborhood"),
    ]
}
