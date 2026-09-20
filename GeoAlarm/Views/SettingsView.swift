// MARK: - File: GeoAlarm/Views/SettingsView.swift
// ═══════════════════════════════════════════════════════════════════════════════
//  GeoAlarm — Location-Based Alarm App (Swift Student Challenge)
//
//  SettingsView provides:
//    • Toggle for Simulation Mode (when real location is available).
//    • Info about how the app uses location data.
//    • Instructions for enabling location in iOS Settings (if denied).
//    • Attribution section explaining this is a Swift Student Challenge project.
//
//  Design refinements:
//    • Section headers use appPrimary-tinted icons.
//    • Privacy info uses appSecondary icon instead of system blue.
//    • Challenge attribution uses appAccent (amber) for the Swift icon.
//    • Permission-denied section uses appAccent (amber) warning tone.
//    • Instruction step numbers use appPrimary.
//    • Bullet points use appPrimary.
//    • appBackground surface for visual cohesion.
// ═══════════════════════════════════════════════════════════════════════════════

import SwiftUI

struct SettingsView: View {

    // MARK: Environment

    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    // MARK: Derived

    /// Whether the user could theoretically use real location.
    private var canUseRealLocation: Bool {
        locationManager.authorizationStatus == .authorizedWhenInUse ||
        locationManager.authorizationStatus == .authorizedAlways
    }

    /// Whether permission was explicitly denied.
    private var isPermissionDenied: Bool {
        locationManager.authorizationStatus == .denied ||
        locationManager.authorizationStatus == .restricted
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            List {
                // ── Mode ─────────────────────────────────────────────
                Section {
                    if canUseRealLocation {
                        Toggle(isOn: Binding(
                            get: { locationManager.isSimulationMode },
                            set: { locationManager.setSimulationMode($0) }
                        )) {
                            Label("Simulation Mode", systemImage: "play.circle")
                        }
                        .tint(Color.appPrimary)
                    } else {
                        HStack {
                            Label("Simulation Mode", systemImage: "play.circle")
                            Spacer()
                            Text("Always On")
                                .font(.appCaption)
                                .foregroundStyle(Color.appTextSecondary)
                        }
                    }
                } header: {
                    Label("Location Mode", systemImage: "location")
                        .foregroundStyle(Color.appPrimary)
                } footer: {
                    if canUseRealLocation {
                        Text("When on, the app uses a virtual location you control instead of your real GPS position.")
                    } else {
                        Text("Location permission is not granted, so the app always runs in Simulation Mode.")
                    }
                }

                // ── Permission Info (if denied) ──────────────────────
                if isPermissionDenied {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Location Permission Denied", systemImage: "exclamationmark.triangle.fill")
                                .font(.appHeadline)
                                .foregroundStyle(Color.appAccent)

                            Text("GeoAlarm is fully functional in Simulation Mode, but if you'd like to use your real location:")
                                .font(.appSubhead)
                                .foregroundStyle(Color.appTextSecondary)

                            VStack(alignment: .leading, spacing: 6) {
                                instructionStep(1, "Open the **Settings** app on your device.")
                                instructionStep(2, "Scroll down and tap **GeoAlarm**.")
                                instructionStep(3, "Tap **Location** and choose **While Using the App**.")
                                instructionStep(4, "Return here and toggle off Simulation Mode.")
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Label("Enable Location", systemImage: "gear")
                            .foregroundStyle(Color.appPrimary)
                    }
                }

                // ── Privacy ──────────────────────────────────────────
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Your Privacy Matters", systemImage: "hand.raised.fill")
                            .font(.appHeadline)
                            .foregroundStyle(Color.appSecondary)

                        Text("""
                        • Your location data **never leaves your device**.
                        • GeoAlarm works **entirely offline** — no server, no analytics.
                        • Location is used only to check if you're near an alarm's target area.
                        • You can switch to Simulation Mode at any time.
                        """)
                        .font(.appSubhead)
                        .foregroundStyle(Color.appTextSecondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Label("Privacy", systemImage: "lock.shield")
                        .foregroundStyle(Color.appPrimary)
                }

                // ── About ────────────────────────────────────────────
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Swift Student Challenge", systemImage: "swift")
                            .font(.appHeadline)
                            .foregroundStyle(Color.appAccent)

                        Text("GeoAlarm is a project built for the **Apple Swift Student Challenge**. It demonstrates:")
                            .font(.appSubhead)
                            .foregroundStyle(Color.appTextSecondary)

                        VStack(alignment: .leading, spacing: 4) {
                            bulletPoint("SwiftUI for a clean, modern interface")
                            bulletPoint("CoreLocation for real-time location monitoring")
                            bulletPoint("Graceful degradation and Simulation Mode")
                            bulletPoint("Pure-Swift geometry engine (Haversine)")
                            bulletPoint("No external dependencies")
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Label("About", systemImage: "info.circle")
                        .foregroundStyle(Color.appPrimary)
                }

                // ── Version ──────────────────────────────────────────
                Section {
                    HStack {
                        Text("Version")
                            .font(.appBody)
                        Spacer()
                        Text("1.0.0")
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    HStack {
                        Text("Platform")
                            .font(.appBody)
                        Spacer()
                        Text("iOS · Swift Playgrounds")
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.appPrimary)
                }
            }
        }
    }

    // MARK: - Helper Views

    /// Step numbers use appPrimary (forest green) for a cohesive look.
    private func instructionStep(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .font(.appSubhead)
                .fontWeight(.bold)
                .foregroundStyle(Color.appPrimary)
                .frame(width: 20, alignment: .trailing)
            Text(.init(text)) // .init enables Markdown rendering
                .font(.appSubhead)
                .foregroundStyle(Color.appTextPrimary)
        }
    }

    /// Bullet points use appPrimary instead of a random accent.
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(Color.appPrimary)
            Text(text)
                .font(.appSubhead)
                .foregroundStyle(Color.appTextSecondary)
        }
    }
}
