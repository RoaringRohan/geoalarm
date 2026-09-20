// MARK: - File: GeoAlarm/Views/AlarmRowView.swift
// ═══════════════════════════════════════════════════════════════════════════════
//  GeoAlarm — Location-Based Alarm App (Swift Student Challenge)
//
//  AlarmRowView renders a single alarm as a card-ready component.
//
//  Design refinements:
//    • Icon circle uses appPrimary (arrival) or appSecondary (departure)
//      for visual variety while staying in the rainforest palette.
//    • Title uses appHeadline + appTextPrimary.
//    • Metadata line uses appCaption + appTextSecondary.
//    • Status badge is the reusable StatusBadge from DesignSystem.swift,
//      which combines color + text (accessible: not color-only).
//    • Disabled alarms get reduced opacity and strikethrough.
//
//  Note: The `.appCard()` modifier is applied by the parent (HomeView)
//  rather than here, so this view can also be used outside of cards.
// ═══════════════════════════════════════════════════════════════════════════════

import SwiftUI

struct AlarmRowView: View {
    let alarm: GeoAlarm
    /// Whether the app is in simulation mode — passed to StatusBadge so it
    /// can distinguish "Sim Triggered" from "Triggered".
    var isSimulation: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            // MARK: Icon
            // Uses a tinted circle: appPrimary for arrival (entering the forest),
            // appSecondary (misty teal) for departure.
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: alarm.triggerType.sfSymbol)
                    .font(.title3)
                    .foregroundStyle(iconColor)
            }

            // MARK: Text
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.title)
                    .font(.appHeadline)
                    .foregroundStyle(alarm.isActive ? Color.appTextPrimary : Color.appTextSecondary)
                    .strikethrough(!alarm.isActive, color: Color.appTextSecondary)

                HStack(spacing: 6) {
                    Text(alarm.triggerType.rawValue)
                    Text("·")
                    Text(alarm.locationName)
                    Text("·")
                    Text(alarm.radiusLabel)
                }
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            // MARK: Status Badge (accessible: color + text)
            StatusBadge(status: alarm.status, isSimulation: isSimulation)
        }
        .opacity(alarm.isActive ? 1 : 0.6)
    }

    // MARK: - Colors

    /// Icon color based on trigger type — keeps visual variety within
    /// the rainforest palette (primary green vs secondary teal).
    private var iconColor: Color {
        alarm.triggerType == .onArrival ? .appPrimary : .appSecondary
    }
}
