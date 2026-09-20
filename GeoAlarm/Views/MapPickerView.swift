// MARK: - File: GeoAlarm/Views/MapPickerView.swift
// ═══════════════════════════════════════════════════════════════════════════════
//  GeoAlarm — Location-Based Alarm App (Swift Student Challenge)
//
//  MapPickerView displays a small SwiftUI Map with:
//    • A pin annotation at the alarm's target coordinate.
//    • A translucent circle overlay showing the alarm radius.
//
//  Design refinements:
//    • Pin and radius circle use appPrimary (rainforest green) instead
//      of system red/blue, maintaining the cohesive palette.
//    • Simulated location marker uses appSecondary (misty teal).
//    • Rounded corners use continuous style for a smoother feel.
//
//  Requires iOS 17+ for the new Map initializer with `MapContentBuilder`.
// ═══════════════════════════════════════════════════════════════════════════════

import SwiftUI
import MapKit

struct MapPickerView: View {
    /// The center coordinate to display.
    let coordinate: CLLocationCoordinate2D

    /// The alarm radius in meters (for the circle overlay).
    let radius: Double

    /// Optional: show the simulated current location as a second marker.
    var simulatedLocation: CLLocationCoordinate2D? = nil

    var body: some View {
        // We compute the camera position to nicely frame the circle.
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radius * 3, // zoom out a bit to show context
            longitudinalMeters: radius * 3
        )

        Map(initialPosition: .region(region)) {
            // Alarm target pin — uses appPrimary (deep canopy green).
            Annotation("Target", coordinate: coordinate) {
                ZStack {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.appPrimary)
                }
            }

            // Radius circle overlay — tinted with appPrimary.
            MapCircle(center: coordinate, radius: radius)
                .foregroundStyle(Color.appPrimary.opacity(0.12))
                .stroke(Color.appPrimary.opacity(0.40), lineWidth: 2)

            // Optional: simulated current location marker — appSecondary teal.
            if let simLoc = simulatedLocation {
                Annotation("You", coordinate: simLoc) {
                    ZStack {
                        Circle()
                            .fill(Color.appSecondary.opacity(0.3))
                            .frame(width: 28, height: 28)
                        Image(systemName: "figure.walk.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.appSecondary)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
